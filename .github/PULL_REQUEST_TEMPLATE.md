## Description

<!-- Provide a brief description of the changes in this PR (minimum 10 characters) -->

## Related Issues

<!-- Link any related issues: Fixes #123, Closes #456 -->

## Files Changed

<!-- List the main files/components affected by this PR -->

## Checklist

- [ ] My PR title follows the conventional commit format (see below)
- [ ] My code follows the project's coding standards
- [ ] I have tested my changes locally
- [ ] I have updated documentation if needed

## Additional Notes

<!-- Any additional context or screenshots -->

---

## 📝 PR Title Format (Required)

Your PR title **must** follow the [Conventional Commits](https://www.conventionalcommits.org/) format:

```
<type>: <description>
```

Or with optional scope:

```
<type>(<scope>): <description>
```

### Valid Types

| Type       | When to Use                                 | Label Applied   |
|------------|---------------------------------------------|-----------------|
| `feat`     | New feature or enhancement                  | `enhancement`   |
| `fix`      | Bug fix                                     | `bug`           |
| `docs`     | Documentation only changes                  | `documentation` |
| `style`    | Code style changes (formatting)             | `style`         |
| `refactor` | Code refactoring (no functional changes)    | `refactor`      |
| `perf`     | Performance improvements                    | `performance`   |
| `test`     | Adding or updating tests                    | `test`          |
| `chore`    | Maintenance tasks (dependencies, configs)   | `chore`         |
| `build`    | Build system or external dependency changes | `build`         |

### Examples

✅ **Valid:**

- `feat: Add new Account trigger handler`
- `fix: Resolve null pointer in ContactService`
- `docs: Update README with setup instructions`
- `feat(apex): Implement bulk processing for leads`

❌ **Invalid:**

- `Add new feature` (missing type prefix)
- `FEAT: Add feature` (uppercase not allowed)
- `feat:Add feature` (missing space after colon)

See [CONTRIBUTING.md](../CONTRIBUTING.md) for full details.
