<!-- docs/i18n-pluralization.md -->
# Rails I18n Pluralization Contract

## Research conclusion

The first static pluralization policy is intentionally configuration-led.

- Rails documents `one` and `other` as the default English forms, with `zero` as an optional special case. It also states that other languages can require more or fewer forms and that the default backend applies only English rules.
- The ruby-i18n default backend selects `zero` when present for zero, then `one` for one and `other` otherwise. Its optional pluralization backend accepts a locale rule returning CLDR-compatible categories and falls back to `other`; applications can replace or extend backend behavior.
- Unicode CLDR defines the cardinal category vocabulary `zero`, `one`, `two`, `few`, `many`, and `other`. Category names describe grammatical minimal pairs, not literal numeric equality; for example, `one` does not universally mean only the number 1.

Sources reviewed September 15, 2026:

- [Rails Internationalization API — Pluralization](https://guides.rubyonrails.org/i18n.html#pluralization)
- [ruby-i18n default backend pluralization](https://github.com/ruby-i18n/i18n/blob/master/lib/i18n/backend/base.rb)
- [ruby-i18n locale-specific pluralization backend](https://github.com/ruby-i18n/i18n/blob/master/lib/i18n/backend/pluralization.rb)
- [Unicode TR35 — Language Plural Rules](https://unicode.org/reports/tr35/tr35-numbers.html#Language_Plural_Rules)

## Supported static policy

`YAML/Rails/I18nPluralizationContract` recognizes a mapping as pluralization-shaped only when all of its immediate keys belong to the CLDR category vocabulary or the explicit numeric keys `0` and `1`. Scalar translations are never treated as pluralization maps.

The default policy validates only English and requires `one` and `other`. Other locales are skipped unless configured under `RequiredCategories`; this avoids embedding incomplete CLDR data or assuming that Rails applications use a particular locale backend. Applications with custom rules can replace the English policy, define exact requirements for any locale, or leave that locale unconfigured.

`CountRequiredCategories` optionally requires `%{count}` in selected category values. It is empty by default because Rails uses `count` to select a branch but does not universally require every rendered branch to display it. `IgnoredPaths` excludes application-specific plural-shaped mappings.

The cop performs no Rails boot, backend discovery, network lookup, ERB execution, translation generation, or autocorrection.

—
Stan Carver II
Made in Texas 🤠
https://stancarver.com
