-- Tailwind Component Helpers
-- Pre-built component class combinations
--
-- @module tailwind.lib.components

local components = {}

--------------------------------------------------------------------------------
-- Button Variants
--------------------------------------------------------------------------------

components.button = {
    base = "inline-flex items-center justify-center gap-2 font-medium rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-black disabled:opacity-50 disabled:pointer-events-none",
    
    sizes = {
        xs = "px-2.5 py-1.5 text-xs",
        sm = "px-3 py-2 text-sm",
        md = "px-4 py-2.5 text-sm",
        lg = "px-5 py-3 text-base",
        xl = "px-6 py-3.5 text-lg",
    },
    
    variants = {
        primary = "bg-copper-500 text-black hover:bg-copper-400 focus:ring-copper-500",
        secondary = "bg-zinc-800 text-white hover:bg-zinc-700 focus:ring-zinc-500",
        outline = "border border-zinc-700 text-white hover:bg-zinc-800 hover:border-copper-500 focus:ring-copper-500",
        ghost = "text-zinc-400 hover:text-white hover:bg-zinc-800 focus:ring-zinc-500",
        danger = "bg-red-600 text-white hover:bg-red-500 focus:ring-red-500",
        link = "text-copper-500 hover:text-copper-400 underline-offset-4 hover:underline",
    },
}

function components.btn(variant, size)
    variant = variant or "primary"
    size = size or "md"
    
    return table.concat({
        components.button.base,
        components.button.sizes[size] or components.button.sizes.md,
        components.button.variants[variant] or components.button.variants.primary,
    }, " ")
end

--------------------------------------------------------------------------------
-- Card Variants
--------------------------------------------------------------------------------

components.card = {
    base = "rounded-xl transition-all duration-200",
    
    variants = {
        default = "bg-zinc-900 border border-zinc-800 hover:border-zinc-700",
        elevated = "bg-zinc-900 shadow-lg shadow-black/20 hover:shadow-xl hover:shadow-black/30",
        outline = "bg-transparent border border-zinc-800 hover:border-copper-500/50",
        ghost = "bg-zinc-900/50 hover:bg-zinc-900",
        interactive = "bg-zinc-900 border border-zinc-800 hover:border-copper-500 hover:shadow-lg hover:shadow-copper-500/5 cursor-pointer",
    },
    
    padding = {
        none = "",
        sm = "p-4",
        md = "p-6",
        lg = "p-8",
    },
}

function components.cardClass(variant, padding)
    variant = variant or "default"
    padding = padding or "md"
    
    return table.concat({
        components.card.base,
        components.card.variants[variant] or components.card.variants.default,
        components.card.padding[padding] or components.card.padding.md,
    }, " ")
end

--------------------------------------------------------------------------------
-- Input Variants
--------------------------------------------------------------------------------

components.input = {
    base = "w-full rounded-lg transition-all duration-200 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-black disabled:opacity-50 disabled:cursor-not-allowed",
    
    sizes = {
        sm = "px-3 py-1.5 text-sm",
        md = "px-4 py-2.5 text-sm",
        lg = "px-4 py-3 text-base",
    },
    
    variants = {
        default = "bg-zinc-900 border border-zinc-800 text-white placeholder-zinc-500 focus:border-copper-500 focus:ring-copper-500/20",
        filled = "bg-zinc-800 border-transparent text-white placeholder-zinc-500 focus:bg-zinc-900 focus:border-copper-500 focus:ring-copper-500/20",
        outline = "bg-transparent border border-zinc-700 text-white placeholder-zinc-500 focus:border-copper-500 focus:ring-copper-500/20",
    },
}

function components.inputClass(variant, size)
    variant = variant or "default"
    size = size or "md"
    
    return table.concat({
        components.input.base,
        components.input.sizes[size] or components.input.sizes.md,
        components.input.variants[variant] or components.input.variants.default,
    }, " ")
end

--------------------------------------------------------------------------------
-- Badge Variants
--------------------------------------------------------------------------------

components.badge = {
    base = "inline-flex items-center font-medium rounded-full",
    
    sizes = {
        sm = "px-2 py-0.5 text-xs",
        md = "px-2.5 py-1 text-xs",
        lg = "px-3 py-1 text-sm",
    },
    
    variants = {
        default = "bg-zinc-800 text-zinc-300",
        primary = "bg-copper-500/20 text-copper-400",
        success = "bg-green-500/20 text-green-400",
        warning = "bg-yellow-500/20 text-yellow-400",
        danger = "bg-red-500/20 text-red-400",
        info = "bg-blue-500/20 text-blue-400",
    },
}

function components.badgeClass(variant, size)
    variant = variant or "default"
    size = size or "md"
    
    return table.concat({
        components.badge.base,
        components.badge.sizes[size] or components.badge.sizes.md,
        components.badge.variants[variant] or components.badge.variants.default,
    }, " ")
end

--------------------------------------------------------------------------------
-- Alert Variants
--------------------------------------------------------------------------------

components.alert = {
    base = "p-4 rounded-lg border",
    
    variants = {
        default = "bg-zinc-900 border-zinc-800 text-zinc-300",
        info = "bg-blue-500/10 border-blue-500/20 text-blue-400",
        success = "bg-green-500/10 border-green-500/20 text-green-400",
        warning = "bg-yellow-500/10 border-yellow-500/20 text-yellow-400",
        danger = "bg-red-500/10 border-red-500/20 text-red-400",
    },
}

function components.alertClass(variant)
    variant = variant or "default"
    
    return table.concat({
        components.alert.base,
        components.alert.variants[variant] or components.alert.variants.default,
    }, " ")
end

--------------------------------------------------------------------------------
-- Layout Utilities
--------------------------------------------------------------------------------

components.layout = {
    container = "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8",
    container_sm = "max-w-3xl mx-auto px-4 sm:px-6",
    container_md = "max-w-5xl mx-auto px-4 sm:px-6 lg:px-8",
    container_lg = "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8",
    container_full = "w-full px-4 sm:px-6 lg:px-8",
    
    section = "py-16 lg:py-24",
    section_sm = "py-8 lg:py-12",
    section_lg = "py-24 lg:py-32",
    
    stack = "flex flex-col",
    stack_sm = "flex flex-col gap-2",
    stack_md = "flex flex-col gap-4",
    stack_lg = "flex flex-col gap-6",
    
    row = "flex flex-row",
    row_sm = "flex flex-row gap-2",
    row_md = "flex flex-row gap-4",
    row_lg = "flex flex-row gap-6",
    
    center = "flex items-center justify-center",
    between = "flex items-center justify-between",
}

--------------------------------------------------------------------------------
-- Typography
--------------------------------------------------------------------------------

components.typography = {
    h1 = "text-4xl lg:text-5xl font-bold tracking-tight text-white",
    h2 = "text-3xl lg:text-4xl font-semibold tracking-tight text-white",
    h3 = "text-2xl font-semibold text-white",
    h4 = "text-xl font-medium text-white",
    h5 = "text-lg font-medium text-white",
    h6 = "text-base font-medium text-white",
    
    body = "text-base text-zinc-400 leading-relaxed",
    body_sm = "text-sm text-zinc-400 leading-relaxed",
    body_lg = "text-lg text-zinc-400 leading-relaxed",
    
    lead = "text-xl text-zinc-300 leading-relaxed",
    muted = "text-sm text-zinc-500",
    
    link = "text-copper-500 hover:text-copper-400 transition-colors",
    link_muted = "text-zinc-400 hover:text-white transition-colors",
}

--------------------------------------------------------------------------------
-- Utility Function
--------------------------------------------------------------------------------

--- Build class string from component definitions
---@param ... string|table Component class strings or conditional tables
---@return string Combined classes
function components.classes(...)
    local result = {}
    
    for _, arg in ipairs({...}) do
        if type(arg) == "string" and arg ~= "" then
            table.insert(result, arg)
        elseif type(arg) == "table" then
            for class, condition in pairs(arg) do
                if condition then
                    table.insert(result, class)
                end
            end
        end
    end
    
    return table.concat(result, " ")
end

return components
