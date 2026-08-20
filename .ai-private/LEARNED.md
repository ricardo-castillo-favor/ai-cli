# Styles

- Pay attention in responsive view (mobile and desktop)
- Use vars instead of fixes values

# React Query

- Query key has the data cache ordered by IDs

# React Performance

- Avoid references, use useMemo or Memo

# NIT code

Examples:

1. cartLimit ? cartLimit instead of: cartLimit !== undefined ? cartLimit

2. if(!itemLimit) return false instead of if (itemLimit === null) return false

3. itemLimitOverride ?? warnings.find(warning => warning.id === 'merchant-groceries-now')?.meta?.groceries_now?.item_limit ?? 15

instead of

itemLimitOverride !== undefined
? itemLimitOverride
: warnings.find(warning => warning.id === 'merchant-groceries-now')?.meta?.groceries_now?.item_limit ?? 15
