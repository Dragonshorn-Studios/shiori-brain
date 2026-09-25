---
layout: default
title: "Skill — Comprehensive PR Review"
shiori_source_id: "z7IgB0vfO1"
---

> Source: [Rughalt/coding-agent-plugins](https://github.com/Rughalt/coding-agent-plugins)

> Comprehensive PR review using specialized agents. Use when asked to review a PR, check changes before committing, or audit code quality. Optionally takes review aspects (comments, tests, errors, types, code, simplify, all).

# Comprehensive PR Review

Run a comprehensive pull request review using multiple specialized agents, each focusing on a different aspect of code quality.

**Review Aspects (optional):** "$ARGUMENTS"

## Review Workflow:
1. **Determine Review Scope**
- Check git status to identify changed files
- Parse arguments to see if user requested specific review aspects
- Default: Run all applicable reviews
1. **Available Review Aspects:**
- **comments** \- Analyze code comment accuracy and maintainability
- **tests** \- Review test coverage quality and completeness
- **errors** \- Check error handling for silent failures
- **types** \- Analyze type design and invariants (if new types added)
- **code** \- General code review for project guidelines
- **simplify** \- Simplify code for clarity and maintainability
- **all** \- Run all applicable reviews (default)
1. **Identify Changed Files**
- Run `git diff --name-only` to see modified files
- Check if PR already exists: `gh pr view`
- Identify file types and what reviews apply
1. **Determine Applicable Reviews**
- **Always applicable**: code-reviewer (general quality)
- **If test files changed**: pr-test-analyzer
- **If comments/docs added**: comment-analyzer
- **If error handling changed**: silent-failure-hunter
- **If types added/modified**: type-design-analyzer
- **After passing review**: code-simplifier (polish and refine)
1. **Launch Review Agents**
- Run agents one at a time, waiting for each report before launching&#10;the next
- Easier to understand and act on
- Good for interactive review
- Launch all agents simultaneously
- Faster for comprehensive review
- Results come back together
1. **Aggregate Results**
- **Critical Issues** (must fix before merge)
- **Important Issues** (should fix)
- **Suggestions** (nice to have)
- **Positive Observations** (what's good)
1. **Provide Action Plan**

## Usage Examples:

**Full review (default):**

``` txt
/pr-review-toolkit:review-pr
```

**Specific aspects:**

``` txt
/pr-review-toolkit:review-pr tests errors
# Reviews only test coverage and error handling

/pr-review-toolkit:review-pr comments
# Reviews only code comments

/pr-review-toolkit:review-pr simplify
# Simplifies code after passing review
```

**Parallel review:**

``` txt
/pr-review-toolkit:review-pr all parallel
# Launches all agents in parallel
```

## Agent Descriptions:

**comment-analyzer**:
- Verifies comment accuracy vs code
- Identifies comment rot
- Checks documentation completeness

**pr-test-analyzer**:
- Reviews behavioral test coverage
- Identifies critical gaps
- Evaluates test quality

**silent-failure-hunter**:
- Finds silent failures
- Reviews catch blocks
- Checks error logging

**type-design-analyzer**:
- Analyzes type encapsulation
- Reviews invariant expression
- Rates type design quality

**code-reviewer**:
- Checks [AGENTS.md/CLAUDE.md](http://AGENTS.md/CLAUDE.md) compliance
- Detects bugs and issues
- Reviews general code quality

**code-simplifier**:
- Simplifies complex code
- Improves clarity and readability
- Applies project standards
- Preserves functionality

## Tips:
- **Run early**: Before creating PR, not after
- **Focus on changes**: Agents analyze git diff by default
- **Address critical first**: Fix high-priority issues before lower priority
- **Re-run after fixes**: Verify issues are resolved
- **Use specific reviews**: Target specific aspects when you know the concern

## Workflow Integration:

**Before committing:**

``` txt
1. Write code
2. Run: /pr-review-toolkit:review-pr code errors
3. Fix any critical issues
4. Commit
```

**Before creating PR:**

``` txt
1. Stage all changes
2. Run: /pr-review-toolkit:review-pr all
3. Address all critical and important issues
4. Run specific reviews again to verify
5. Create PR
```

**After PR feedback:**

``` txt
1. Make requested changes
2. Run targeted reviews based on feedback
3. Verify issues are resolved
4. Push updates
```

## Notes:
- Agents run autonomously and return detailed reports
- Each agent focuses on its specialty for deep analysis
- Results are actionable with specific file:line references
