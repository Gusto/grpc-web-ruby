## Testing

### Running tests

Use the `rake` command to run the entire test suite. This runs on docker due to a dependency on Envoy.

### Unit tests

Unit tests can be run without docker by running `rspec spec/unit`

### Pull Request title/description format

Each Pull Request description consists of a **header**, a **body** and a **footer**. The header has a special format that includes a **type**, a **scope** and a **subject**:

```commit
<type>(<scope>): <subject>
<BLANK LINE>
<body>
<BLANK LINE>
<footer>
```

The **header** is mandatory and the **scope** of the header is optional.

The **footer** can contain a [closing reference to an issue](https://help.github.com/articles/closing-issues-via-commit-messages).

#### Revert

If the commit reverts a previous commit, it should begin with `revert: `, followed by the header of the reverted commit. In the body it should say: `This reverts commit <hash>.`, where the hash is the SHA of the commit being reverted.

#### Type

The type must be one of the following:

| Type         | Description                                                                                                 |
|--------------|-------------------------------------------------------------------------------------------------------------|
| **build**    | Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm)         |
| **ci**       | Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs) |
| **docs**     | Documentation only changes                                                                                  |
| **feat**     | A new feature                                                                                               |
| **fix**      | A bug fix                                                                                                   |
| **perf**     | A code change that improves performance                                                                     |
| **refactor** | A code change that neither fixes a bug nor adds a feature                                                   |
| **style**    | Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc)      |
| **test**     | Adding missing tests or correcting existing tests                                                           |
| **chore**    | Any other change that does not affect the published code (e.g. tool changes, config changes)                |

#### Subject

The subject contains succinct description of the change:

- use the imperative, present tense: "change" not "changed" nor "changes"
- no dot (.) at the end

#### Body
Just as in the **subject**, use the imperative, present tense: "change" not "changed" nor "changes".
The body should include the motivation for the change and contrast this with previous behavior.

#### Footer
The footer should contain any information about **Breaking Changes** and is also the place to reference GitHub issues that this commit **Closes**.

**Breaking Changes** should start with the word `BREAKING CHANGE:` with a space or two newlines. The rest of the commit message is then used for this.

#### Examples

```commit
`fix(pencil): stop graphite breaking when too much pressure applied`
```

```commit
`feat(pencil): add 'graphiteWidth' option`

Fix #42
```

```commit
perf(pencil): remove graphiteWidth option`

BREAKING CHANGE: The graphiteWidth option has been removed.

The default graphite width of 10mm is always used for performance reasons.
```
