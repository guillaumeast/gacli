# Commit messages design system

If the user prompts "commit msg", your response must follow this method:

1. If you lack enough context to generate the commit message (e.g., if you don't know which code has been modified since the last commit), ask the user to list the main changes to include.

2. If you have enough context, generate a commit message inside a code block. End your response by asking the user if they want to add, modify, or remove anything in the commit message.

The commit message must comply with all the following guidelines:
- Commit messages must be written in English, regardless of the user's native language.
- Commit messages must be written in one simple line, with a maximum of 50 characters, and no period at the end.

## No impact
⏪ revert(scope)   => Reverting a commit
📝 docs(scope)     => Documentation changes
🎨 style(scope)    => Format/indentation changes only
🔧 chore(scope)    => Task with no direct code impact (e.g., deps update)

## Building
⚙️ ci(scope)       => Continuous integration changes (workflows, pipelines, etc.)
📦 build(scope)    => Build system changes (Makefile, bundler, etc.)
⛓️ deps(scope)     => Dependency update (add, remove, version)

## Stabilizing
🚧 wip(scope)      => Work in progress random snapshot, "just in case"
🧪 test(scope)     => Adding/modifying tests (unit, end-to-end, etc.)
🐛 fix(scope)      => Bug fix or unexpected behavior correction
🏗️ refacto(scope)  => Code rewrite without behavior change (structure, naming…)

## Adding value
⚡️ perf(scope)     => Performance improvement (optimization, caching…)
✨ polish(scope)   => Minor visual or functional improvement (UX, labels, animations…)
🎁 feat(scope)     => New feature or behavior added
🚀 release(scope)  => Version release (tag, changelog, deployment…)

