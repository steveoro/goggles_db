# "Following a reference implementation" - a.k.a., "following the same approach" (as some other code)

## 1.1. It's "almost a copy-paste" operation
Ideally, source code should be copied over the destination implementation and then adapted in naming and data fields for the requested implementation.

**Rails example:**
Prompt: "Implement the CRUD actions for model B using the same approach as model A"
*Reference response reasoning with task analysis:*
```markdown
- Purpose: implement working Create, Read, Update and Delete actions for controller class of model B, using same ideas from model A
- Implementation Steps:
    0. assume schema file is the only source of truth
    1. check target structure of model/table B directly on schema file and compare differences with model A
    2. implement new controller actions for target model B: if available, use the same code from controller A and adapt it according to differences in data fields
    3. implement target views reusing same code from source views (if available) and adapting the source code to differences in data fields
    4. respect usage of components or helper classes: if source views are using custom components, replicate its usage; if a component being used is specific to model A, recreate a new specialized version of it for model B.
    5. implement any new specs needed to cover all the added actions, views, helpers or components, so that the overall test coverage does not decay.
    6. run tests to verify the new code; in case of errors, fix them or, if you're not able to do that, end with a comprehensive report of what possibly could have gone wrong.
    7. if tests are green and refactoring is advised, suggest what to do.
```

Goal advantages:
- Reduced mental load when comparing features that have a very similar implementation.
- Quality is higher because similar code is easier to maintain.
- Refactoring can always be done later on, over multiple places with similar code, once all the business logic is consolidated and covered by tests.

## 1.2. Namespacing, scope, code and file structure MUST be preserved

**Example:**
- Carrying over the same example from point 1.1 above, if a localized text has a namespace like "crud.form.<action>.title", this namespace hierarchy MUST be preserved as it is, changing, if needed, only the action name but NOT the overall hierarchy. (So, something like "crud.form.edit.title" is good, but NOT "crud.form.action.edit.title", nor "crud.form.title.edit".)
In case of doubt, always check the source code and/or the actual localization files (under "config/locales" for Rails)

## 1.3. UI styling, "look and feel", CSS classes and component usage MUST be preserved.

**Example:**
- Carrying over the same example from point 1.1 above, if a view element uses certain CSS classes, these must be reused as they are, unless the CSS class usage is clearly made just for identifying or grouping together model-specific features tied to source model A; in this latter case, we'll need similar new CSS classes for the target model B.

Practical examples:
- source classes: "btn btn-primary" => target classes: "btn btn-primary"
- source classes: "btn model-a-post" => target classes: "btn model-b-post"
- if the source view makes use of certain CSS classes for styling a grid (like "card card-body > row"), replicate the same structure in the target view, using the *same* CSS classes

