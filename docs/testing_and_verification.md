# Testing and verification
- Adding code implies adding tests for it, as overall code coverage ratio must be kept as high as possible
- Editing code implies revising its associated tests
- Run any new or updated tests to verify that they are passing
- In case of errors, fix them by addressing any issue found in the implementation
- If tests are missing or lacking coverage, add them.
- Prefer randomization for fixture or domain data using tools like FFaker over hard-coded or static values whenever possible
- Always add any missing factory class for a model
- Reuse existing test helpers, step implementations or shared examples to keep code DRY

## Tricks: generalize accessing DOM elements for tests
Generalize tests by adding a DOM ID which is possibly unique on the web page, or by adding a special bespoke CSS class or a data attribute to a field or div element that needs to be tested or checked for presence.

**Advantage**: allows you to target that specific element type and perform checks on the page without referencing long CSS styling class chains (like `class: "btn btn-sm btn-primary"`) or labels (like `text: "Edit"`) that may easily change in future edits, while also reducing the needed test maintenance.

**Example**: addressing a specific type of button on a page.
Use something like: `#btn-row-edit` (preferred) or `.btn-row-edit` or `data: 'row-edit'`.

**Example**: addressing a specific button on a page when there are multiple buttons of that same type, like an edit button for a specific row model.
Use something like: `#btn-row-edit-<id>` (preferred) or `.btn-row-edit-<id>` or `data: 'row-edit-<id>'`.

