#!/usr/bin/env bash
# Stage Dependency Graph Analyzer
# Analyzes stage dependencies and determines execution order

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Project root
PROJECT_ROOT="${PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
ROADMAP_FILE="${PROJECT_ROOT}/docs/stages/stage-roadmap.md"

# Dependency graph (adjacency list)
declare -A DEPENDENCIES
declare -A STAGES
declare -A STAGE_STATUS

# Parse roadmap to extract dependencies
parse_roadmap() {
    print_info "Parsing roadmap: $ROADMAP_FILE"

    if [[ ! -f "$ROADMAP_FILE" ]]; then
        print_error "Roadmap file not found: $ROADMAP_FILE"
        return 1
    fi

    local current_stage=""
    local in_stage_table=false

    while IFS= read -r line; do
        # Check for stage table
        if [[ "$line" =~ ^\|[[:space:]]*Stage[[:space:]]*\| ]]; then
            in_stage_table=true
            continue
        fi

        # Parse table rows
        if [[ "$in_stage_table" == true ]] && [[ "$line" =~ ^\|[[:space:]]*([0-9]+)[[:space:]]*\| ]]; then
            local stage_num="${BASH_REMATCH[1]}"
            local stage_name=""
            local stage_status=""
            local stage_deps=""

            # Extract fields
            IFS='|' read -ra fields <<< "$line"
            if [[ ${#fields[@]} -ge 5 ]]; then
                stage_num=$(echo "${fields[1]}" | tr -d ' ')
                stage_name=$(echo "${fields[2]}" | tr -d ' ')
                stage_status=$(echo "${fields[3]}" | tr -d ' ')
                stage_deps=$(echo "${fields[5]}" | tr -d ' ')

                # Store stage info
                STAGES["$stage_num"]="$stage_name"
                STAGE_STATUS["$stage_num"]="$stage_status"

                # Parse dependencies
                if [[ -n "$stage_deps" ]] && [[ "$stage_deps" != "None" ]]; then
                    DEPENDENCIES["$stage_num"]="$stage_deps"
                else
                    DEPENDENCIES["$stage_num"]=""
                fi
            fi
        fi

        # End of table
        if [[ "$in_stage_table" == true ]] && [[ ! "$line" =~ ^\| ]]; then
            in_stage_table=false
        fi
    done < "$ROADMAP_FILE"

    print_success "Parsed ${#STAGES[@]} stages"
}

# Get dependencies for a stage
get_dependencies() {
    local stage="$1"
    echo "${DEPENDENCIES[$stage]:-}"
}

# Check if stage can run (all dependencies complete)
can_run() {
    local stage="$1"
    local deps="${DEPENDENCIES[$stage]:-}"

    if [[ -z "$deps" ]] || [[ "$deps" == "None" ]]; then
        return 0
    fi

    # Parse dependencies (comma or space separated)
    for dep in $(echo "$deps" | tr ',' ' '); do
        dep=$(echo "$dep" | tr -d ' ')
        if [[ -n "$dep" ]]; then
            local status="${STAGE_STATUS[$dep]:-}"
            if [[ "$status" != "✅" ]] && [[ "$status" != "Completed" ]] && [[ "$status" != "Complete" ]]; then
                return 1
            fi
        fi
    done

    return 0
}

# Find stages that can run in parallel
find_parallel_stages() {
    local from_stage="${1:-1}"
    local to_stage="${2:-999}"
    local stages=()

    for stage in "${!STAGES[@]}"; do
        if [[ "$stage" -ge "$from_stage" ]] && [[ "$stage" -le "$to_stage" ]]; then
            if can_run "$stage"; then
                stages+=("$stage")
            fi
        fi
    done

    echo "${stages[*]}"
}

# Build execution plan
build_execution_plan() {
    local from_stage="${1:-1}"
    local to_stage="${2:-999}"
    local max_parallel="${3:-3}"

    print_info "Building execution plan for stages $from_stage to $to_stage"

    local plan=()
    local remaining_stages=()

    # Collect all stages in range
    for stage in "${!STAGES[@]}"; do
        if [[ "$stage" -ge "$from_stage" ]] && [[ "$stage" -le "$to_stage" ]]; then
            remaining_stages+=("$stage")
        fi
    done

    # Sort remaining stages
    IFS=$'\n' remaining_stages=($(sort -n <<<"${remaining_stages[*]}")); unset IFS

    local iteration=0
    while [[ ${#remaining_stages[@]} -gt 0 ]]; do
        iteration=$((iteration + 1))
        local parallel_group=()
        local new_remaining=()

        for stage in "${remaining_stages[@]}"; do
            # Check if all dependencies are in previous groups
            local deps_met=true
            local deps="${DEPENDENCIES[$stage]:-}"

            for dep in $(echo "$deps" | tr ',' ' '); do
                dep=$(echo "$dep" | tr -d ' ')
                if [[ -n "$dep" ]]; then
                    # Check if dep is in remaining stages
                    for rem in "${remaining_stages[@]}" "${parallel_group[@]}"; do
                        if [[ "$rem" == "$dep" ]]; then
                            deps_met=false
                            break
                        fi
                    done
                fi
            done

            if [[ "$deps_met" == true ]]; then
                if [[ ${#parallel_group[@]} -lt "$max_parallel" ]]; then
                    parallel_group+=("$stage")
                else
                    new_remaining+=("$stage")
                fi
            else
                new_remaining+=("$stage")
            fi
        done

        if [[ ${#parallel_group[@]} -gt 0 ]]; then
            plan+=("$(IFS=,; echo "${parallel_group[*]}")")
        fi

        remaining_stages=("${new_remaining[@]}")

        # Prevent infinite loop
        if [[ $iteration -gt 100 ]]; then
            print_error "Could not build execution plan - circular dependency?"
            return 1
        fi
    done

    # Output plan
    echo "Execution Plan:"
    local group_num=0
    for group in "${plan[@]}"; do
        group_num=$((group_num + 1))
        IFS=',' read -ra stages <<< "$group"
        if [[ ${#stages[@]} -gt 1 ]]; then
            echo "  Group $group_num (parallel): ${stages[*]}"
        else
            echo "  Group $group_num (sequential): ${stages[*]}"
        fi
    done
}

# Draw dependency graph
draw_dependency_graph() {
    local from_stage="${1:-1}"
    local to_stage="${2:-999}"

    echo ""
    echo "Dependency Graph:"
    echo ""

    for stage in $(echo "${!STAGES[@]}" | tr ' ' '\n' | sort -n); do
        if [[ "$stage" -ge "$from_stage" ]] && [[ "$stage" -le "$to_stage" ]]; then
            local deps="${DEPENDENCIES[$stage]:-}"
            local name="${STAGES[$stage]:-Unknown}"
            local status="${STAGE_STATUS[$stage]:-⏳}"

            if [[ -z "$deps" ]] || [[ "$deps" == "None" ]]; then
                echo "  Stage $stage: $name [$status] (no deps)"
            else
                echo "  Stage $stage: $name [$status] ← deps: $deps"
            fi
        fi
    done

    echo ""
}

# Estimate duration
estimate_duration() {
    local from_stage="${1:-1}"
    local to_stage="${2:-999}"
    local avg_stage_hours="${3:-2}"

    local stage_count=0
    for stage in "${!STAGES[@]}"; do
        if [[ "$stage" -ge "$from_stage" ]] && [[ "$stage" -le "$to_stage" ]]; then
            stage_count=$((stage_count + 1))
        fi
    done

    # Rough estimate: sequential vs parallel
    local sequential_hours=$((stage_count * avg_stage_hours))
    local parallel_groups=$(( (stage_count + 1) / 2 ))  # Assume ~2 parallel on average
    local parallel_hours=$((parallel_groups * avg_stage_hours))

    echo ""
    echo "Estimated Duration:"
    echo "  Sequential: $sequential_hours hours ($stage_count stages × ${avg_stage_hours}h)"
    echo "  Parallel (max 2): $parallel_hours hours (~$parallel_groups groups × ${avg_stage_hours}h)"
    echo ""
}

# Print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Main function
main() {
    local command="${1:-graph}"
    shift 2>/dev/null || true

    case "$command" in
        parse)
            parse_roadmap
            ;;
        deps)
            local stage="$1"
            parse_roadmap > /dev/null 2>&1
            get_dependencies "$stage"
            ;;
        can-run)
            local stage="$1"
            parse_roadmap > /dev/null 2>&1
            if can_run "$stage"; then
                echo "true"
            else
                echo "false"
            fi
            ;;
        parallel)
            local from="${1:-1}"
            local to="${2:-999}"
            parse_roadmap > /dev/null 2>&1
            find_parallel_stages "$from" "$to"
            ;;
        plan)
            local from="${1:-1}"
            local to="${2:-999}"
            local max="${3:-3}"
            parse_roadmap > /dev/null 2>&1
            build_execution_plan "$from" "$to" "$max"
            ;;
        graph)
            local from="${1:-1}"
            local to="${2:-999}"
            parse_roadmap > /dev/null 2>&1
            draw_dependency_graph "$from" "$to"
            ;;
        estimate)
            local from="${1:-1}"
            local to="${2:-999}"
            local hours="${3:-2}"
            parse_roadmap > /dev/null 2>&1
            estimate_duration "$from" "$to" "$hours"
            ;;
        all)
            local from="${1:-1}"
            local to="${2:-999}"
            local max="${3:-3}"
            parse_roadmap > /dev/null 2>&1
            draw_dependency_graph "$from" "$to"
            build_execution_plan "$from" "$to" "$max"
            estimate_duration "$from" "$to"
            ;;
        *)
            echo "Usage: $0 {parse|deps|can-run|parallel|plan|graph|estimate|all}"
            echo ""
            echo "Commands:"
            echo "  parse      - Parse roadmap file"
            echo "  deps N     - Get dependencies for stage N"
            echo "  can-run N  - Check if stage N can run (deps complete)"
            echo "  parallel   - Find stages that can run in parallel"
            echo "  plan       - Build execution plan"
            echo "  graph      - Draw dependency graph"
            echo "  estimate   - Estimate duration"
            echo "  all        - Show all information"
            exit 1
            ;;
    esac
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
