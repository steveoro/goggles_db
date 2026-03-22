---
description: Keep locale files in sync across goggles_db (engine) and consumer apps — YAML structure, model labels, views, and tests
auto_execution_mode: 2
---

# i18n Sync

Use this skill when adding, renaming, or updating i18n locale keys across the Goggles framework. Because `goggles_db` is a shared engine, locale changes must be coordinated with consumer projects.

## Locale File Locations

### goggles_db (engine — base locales)

Path: `/home/steve/Projects/goggles_db/config/locales/`

- `application_lookup_entities.en.yml` — English labels for lookup types and model attributes
- `application_lookup_entities.it.yml` — Italian labels
- `devise.en.yml` / `devise.it.yml` — Devise authentication messages

These are **shared** across all consumer projects via the engine.

### goggles_api

Path: `/home/steve/Projects/goggles_api/config/locales/`

- API-specific messages (error responses, status messages)

### goggles_main

Path: `/home/steve/Projects/goggles_main/config/locales/`

- View-specific labels, page titles, flash messages, form labels
- Can override engine keys with project-specific values

### goggles_admin2

Path: `/home/steve/Projects/goggles_admin2/config/locales/`

- Admin-specific labels, import status messages, merge messages
- Can override engine keys with project-specific values

## Key Principles

1. **Engine locales are shared**: Keys defined in `goggles_db` are available in all consumer projects
2. **Consumer locales can override**: A key defined in both engine and consumer will use the consumer's value
3. **Always add both `en` and `it`**: The framework is bilingual (English + Italian)
4. **Rails namespacing**: Engine locale keys are typically under `activerecord.models.goggles_db/*` and `activerecord.attributes.goggles_db/*`

## Adding New Locale Keys

### For a New Model (in goggles_db)

Edit `config/locales/application_lookup_entities.en.yml`:

```yaml
en:
  activerecord:
    models:
      goggles_db/<model_name>:
        one: "Model Name"
        other: "Model Names"
    attributes:
      goggles_db/<model_name>:
        column_name: "Column Label"
```

And the Italian counterpart in `application_lookup_entities.it.yml`:

```yaml
it:
  activerecord:
    models:
      goggles_db/<model_name>:
        one: "Nome Modello"
        other: "Nomi Modello"
    attributes:
      goggles_db/<model_name>:
        column_name: "Etichetta Colonna"
```

### For View Labels (in consumer projects)

Add keys under a project-specific namespace:

```yaml
en:
  <controller_name>:
    <action_name>:
      title: "Page Title"
      description: "Page description"
```

### For Flash Messages

```yaml
en:
  flash:
    <controller>:
      <action>:
        success: "Operation successful"
        error: "Something went wrong"
```

## Sync Checklist

When adding or changing locale keys:

- [ ] Add/update key in `goggles_db` English locale file
- [ ] Add/update key in `goggles_db` Italian locale file
- [ ] Run `./update_engine.sh` in consumer projects (if engine locales changed)
- [ ] Check for overrides in `goggles_main/config/locales/` that may need updating
- [ ] Check for overrides in `goggles_admin2/config/locales/` that may need updating
- [ ] Search for hardcoded strings that should use the new key: `grep -rn 'hardcoded text' app/`
- [ ] Verify in browser (both English and Italian)

## Finding Missing Translations

```bash
# Search for missing translation markers in views:
grep -rn 'translation missing' app/views/ tmp/

# Search for i18n calls that might reference non-existent keys:
grep -rn "I18n.t(" app/ --include='*.rb' | grep -v 'spec/'
grep -rn "= t(" app/ --include='*.haml'
```

## Testing

Rails will raise `I18n::MissingTranslationData` in test mode if `config.action_view.raise_on_missing_translations = true` is set. Otherwise, missing keys render as `"translation missing: en.key.path"` — search test output for this string.
