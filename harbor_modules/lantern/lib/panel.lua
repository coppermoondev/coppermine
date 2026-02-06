-- Lantern Panel
-- Generates the HTML/CSS/JS for the debug toolbar
--
-- @module lantern.lib.panel

local panel = {}

--------------------------------------------------------------------------------
-- CSS Styles
--------------------------------------------------------------------------------

local function getStyles()
    return [[
<style id="lantern-styles">
/* Lantern Debug Toolbar */
:root {
    --lantern-bg: #1e1e2e;
    --lantern-bg-secondary: #313244;
    --lantern-bg-tertiary: #45475a;
    --lantern-text: #cdd6f4;
    --lantern-text-muted: #a6adc8;
    --lantern-accent: #f5c2e7;
    --lantern-success: #a6e3a1;
    --lantern-warning: #f9e2af;
    --lantern-error: #f38ba8;
    --lantern-info: #89b4fa;
    --lantern-border: #585b70;
    --lantern-shadow: rgba(0, 0, 0, 0.3);
}

#lantern-badge {
    position: fixed;
    bottom: 20px;
    right: 20px;
    width: 48px;
    height: 48px;
    background: linear-gradient(135deg, #f5c2e7 0%, #cba6f7 100%);
    border-radius: 50%;
    cursor: pointer;
    z-index: 999998;
    display: flex;
    align-items: center;
    justify-content: center;
    box-shadow: 0 4px 12px var(--lantern-shadow);
    transition: transform 0.2s ease, box-shadow 0.2s ease;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
}

#lantern-badge:hover {
    transform: scale(1.1);
    box-shadow: 0 6px 16px var(--lantern-shadow);
}

#lantern-badge svg {
    width: 24px;
    height: 24px;
    fill: #1e1e2e;
}

#lantern-badge-info {
    position: absolute;
    top: -8px;
    right: -8px;
    background: var(--lantern-error);
    color: #1e1e2e;
    font-size: 11px;
    font-weight: 700;
    padding: 2px 6px;
    border-radius: 10px;
    min-width: 20px;
    text-align: center;
}

#lantern-panel {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 0;
    background: var(--lantern-bg);
    z-index: 999999;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    font-size: 13px;
    color: var(--lantern-text);
    box-shadow: 0 -4px 20px var(--lantern-shadow);
    transition: height 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    overflow: hidden;
    display: flex;
    flex-direction: column;
}

#lantern-panel.open {
    height: 45vh;
    min-height: 300px;
    max-height: 600px;
}

#lantern-panel.maximized {
    height: 85vh;
}

/* Header */
#lantern-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 16px;
    height: 44px;
    min-height: 44px;
    background: var(--lantern-bg-secondary);
    border-bottom: 1px solid var(--lantern-border);
}

#lantern-title {
    display: flex;
    align-items: center;
    gap: 10px;
    font-weight: 600;
    color: var(--lantern-accent);
}

#lantern-title svg {
    width: 20px;
    height: 20px;
    fill: currentColor;
}

#lantern-summary {
    display: flex;
    align-items: center;
    gap: 16px;
    font-size: 12px;
}

.lantern-summary-item {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 4px 10px;
    background: var(--lantern-bg-tertiary);
    border-radius: 4px;
}

.lantern-summary-item.success { color: var(--lantern-success); }
.lantern-summary-item.warning { color: var(--lantern-warning); }
.lantern-summary-item.error { color: var(--lantern-error); }
.lantern-summary-item.info { color: var(--lantern-info); }

#lantern-controls {
    display: flex;
    align-items: center;
    gap: 8px;
}

.lantern-btn {
    background: transparent;
    border: none;
    color: var(--lantern-text-muted);
    cursor: pointer;
    padding: 6px;
    border-radius: 4px;
    display: flex;
    align-items: center;
    justify-content: center;
    transition: background 0.15s, color 0.15s;
}

.lantern-btn:hover {
    background: var(--lantern-bg-tertiary);
    color: var(--lantern-text);
}

.lantern-btn svg {
    width: 18px;
    height: 18px;
    fill: currentColor;
}

/* Tabs */
#lantern-tabs {
    display: flex;
    align-items: center;
    padding: 0 16px;
    height: 40px;
    min-height: 40px;
    background: var(--lantern-bg-secondary);
    border-bottom: 1px solid var(--lantern-border);
    gap: 4px;
    overflow-x: auto;
}

.lantern-tab {
    display: flex;
    align-items: center;
    gap: 6px;
    padding: 8px 14px;
    border-radius: 6px 6px 0 0;
    cursor: pointer;
    color: var(--lantern-text-muted);
    font-size: 12px;
    font-weight: 500;
    transition: background 0.15s, color 0.15s;
    white-space: nowrap;
    border: none;
    background: transparent;
}

.lantern-tab:hover {
    background: var(--lantern-bg-tertiary);
    color: var(--lantern-text);
}

.lantern-tab.active {
    background: var(--lantern-bg);
    color: var(--lantern-accent);
    border-bottom: 2px solid var(--lantern-accent);
    margin-bottom: -1px;
}

.lantern-tab-badge {
    background: var(--lantern-bg-tertiary);
    padding: 2px 6px;
    border-radius: 10px;
    font-size: 10px;
    font-weight: 600;
}

.lantern-tab.active .lantern-tab-badge {
    background: var(--lantern-accent);
    color: var(--lantern-bg);
}

.lantern-tab-badge.error {
    background: var(--lantern-error);
    color: var(--lantern-bg);
}

/* Content */
#lantern-content {
    flex: 1;
    overflow: hidden;
    position: relative;
}

.lantern-tab-content {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    overflow: auto;
    padding: 16px;
    display: none;
}

.lantern-tab-content.active {
    display: block;
}

/* Tables */
.lantern-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 12px;
}

.lantern-table th,
.lantern-table td {
    padding: 8px 12px;
    text-align: left;
    border-bottom: 1px solid var(--lantern-border);
}

.lantern-table th {
    background: var(--lantern-bg-secondary);
    color: var(--lantern-text-muted);
    font-weight: 600;
    text-transform: uppercase;
    font-size: 10px;
    letter-spacing: 0.5px;
    position: sticky;
    top: 0;
}

.lantern-table tr:hover td {
    background: var(--lantern-bg-secondary);
}

.lantern-table td.key {
    color: var(--lantern-accent);
    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
    width: 200px;
}

.lantern-table td.value {
    color: var(--lantern-text);
    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
    word-break: break-all;
}

/* Cards */
.lantern-card {
    background: var(--lantern-bg-secondary);
    border-radius: 8px;
    padding: 16px;
    margin-bottom: 16px;
}

.lantern-card-title {
    font-weight: 600;
    margin-bottom: 12px;
    display: flex;
    align-items: center;
    gap: 8px;
}

/* Sections */
.lantern-section {
    margin-bottom: 24px;
}

.lantern-section-title {
    font-size: 11px;
    font-weight: 600;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    color: var(--lantern-text-muted);
    margin-bottom: 12px;
    padding-bottom: 8px;
    border-bottom: 1px solid var(--lantern-border);
}

/* Badges & Status */
.lantern-status {
    display: inline-flex;
    align-items: center;
    padding: 4px 10px;
    border-radius: 4px;
    font-size: 12px;
    font-weight: 600;
}

.lantern-status.success { background: rgba(166, 227, 161, 0.2); color: var(--lantern-success); }
.lantern-status.warning { background: rgba(249, 226, 175, 0.2); color: var(--lantern-warning); }
.lantern-status.error { background: rgba(243, 139, 168, 0.2); color: var(--lantern-error); }
.lantern-status.info { background: rgba(137, 180, 250, 0.2); color: var(--lantern-info); }

/* Method badges */
.lantern-method {
    display: inline-block;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 11px;
    font-weight: 700;
    text-transform: uppercase;
}

.lantern-method.GET { background: rgba(137, 180, 250, 0.2); color: var(--lantern-info); }
.lantern-method.POST { background: rgba(166, 227, 161, 0.2); color: var(--lantern-success); }
.lantern-method.PUT { background: rgba(249, 226, 175, 0.2); color: var(--lantern-warning); }
.lantern-method.PATCH { background: rgba(245, 194, 231, 0.2); color: var(--lantern-accent); }
.lantern-method.DELETE { background: rgba(243, 139, 168, 0.2); color: var(--lantern-error); }

/* Query type badges */
.lantern-query-type {
    display: inline-block;
    padding: 2px 8px;
    border-radius: 4px;
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    margin-right: 8px;
}

.lantern-query-type.SELECT { background: rgba(137, 180, 250, 0.2); color: var(--lantern-info); }
.lantern-query-type.INSERT { background: rgba(166, 227, 161, 0.2); color: var(--lantern-success); }
.lantern-query-type.UPDATE { background: rgba(249, 226, 175, 0.2); color: var(--lantern-warning); }
.lantern-query-type.DELETE { background: rgba(243, 139, 168, 0.2); color: var(--lantern-error); }
.lantern-query-type.CREATE { background: rgba(245, 194, 231, 0.2); color: var(--lantern-accent); }
.lantern-query-type.DROP { background: rgba(243, 139, 168, 0.3); color: var(--lantern-error); }
.lantern-query-type.ALTER { background: rgba(249, 226, 175, 0.2); color: var(--lantern-warning); }
.lantern-query-type.EXECUTE { background: rgba(166, 173, 200, 0.2); color: var(--lantern-text-muted); }
.lantern-query-type.UNKNOWN { background: rgba(166, 173, 200, 0.2); color: var(--lantern-text-muted); }

/* SQL syntax highlighting */
.lantern-sql-keyword { color: var(--lantern-accent); font-weight: 600; }
.lantern-sql-string { color: var(--lantern-success); }
.lantern-sql-number { color: var(--lantern-info); }
.lantern-sql-function { color: var(--lantern-warning); }
.lantern-sql-table { color: #fab387; }
.lantern-sql-param { color: var(--lantern-warning); background: rgba(249, 226, 175, 0.1); padding: 1px 4px; border-radius: 3px; }

/* Query row slow highlight */
.lantern-query-slow {
    background: rgba(243, 139, 168, 0.1) !important;
}

.lantern-query-slow td {
    background: inherit !important;
}

/* Log levels */
.lantern-log {
    display: flex;
    align-items: flex-start;
    gap: 12px;
    padding: 8px 12px;
    border-radius: 4px;
    margin-bottom: 4px;
    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
    font-size: 12px;
}

.lantern-log.debug { background: rgba(137, 180, 250, 0.1); }
.lantern-log.info { background: rgba(166, 227, 161, 0.1); }
.lantern-log.warning { background: rgba(249, 226, 175, 0.1); }
.lantern-log.error { background: rgba(243, 139, 168, 0.1); }

.lantern-log-level {
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    min-width: 60px;
}

.lantern-log.debug .lantern-log-level { color: var(--lantern-info); }
.lantern-log.info .lantern-log-level { color: var(--lantern-success); }
.lantern-log.warning .lantern-log-level { color: var(--lantern-warning); }
.lantern-log.error .lantern-log-level { color: var(--lantern-error); }

.lantern-log-time {
    color: var(--lantern-text-muted);
    font-size: 10px;
    min-width: 70px;
}

.lantern-log-message {
    flex: 1;
    word-break: break-word;
}

/* Code blocks */
.lantern-code {
    background: var(--lantern-bg-tertiary);
    padding: 12px;
    border-radius: 6px;
    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
    font-size: 12px;
    overflow-x: auto;
    white-space: pre-wrap;
    word-break: break-all;
}

/* JSON viewer */
.lantern-json {
    font-family: 'SF Mono', Monaco, 'Courier New', monospace;
    font-size: 12px;
}

.lantern-json-key { color: var(--lantern-accent); }
.lantern-json-string { color: var(--lantern-success); }
.lantern-json-number { color: var(--lantern-info); }
.lantern-json-boolean { color: var(--lantern-warning); }
.lantern-json-null { color: var(--lantern-text-muted); }

/* Timeline */
.lantern-timeline {
    position: relative;
    padding-left: 24px;
}

.lantern-timeline-item {
    position: relative;
    padding: 8px 0 8px 20px;
    border-left: 2px solid var(--lantern-border);
}

.lantern-timeline-item::before {
    content: '';
    position: absolute;
    left: -6px;
    top: 12px;
    width: 10px;
    height: 10px;
    background: var(--lantern-accent);
    border-radius: 50%;
}

.lantern-timeline-time {
    font-size: 10px;
    color: var(--lantern-text-muted);
    margin-bottom: 4px;
}

.lantern-timeline-label {
    font-weight: 500;
}

/* Stats grid */
.lantern-stats {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
    gap: 12px;
    margin-bottom: 20px;
}

.lantern-stat {
    background: var(--lantern-bg-secondary);
    padding: 16px;
    border-radius: 8px;
    text-align: center;
}

.lantern-stat-value {
    font-size: 24px;
    font-weight: 700;
    color: var(--lantern-accent);
}

.lantern-stat-label {
    font-size: 11px;
    color: var(--lantern-text-muted);
    text-transform: uppercase;
    margin-top: 4px;
}

/* Empty state */
.lantern-empty {
    text-align: center;
    padding: 40px 20px;
    color: var(--lantern-text-muted);
}

.lantern-empty-icon {
    font-size: 48px;
    margin-bottom: 12px;
    opacity: 0.5;
}

/* Scrollbar */
#lantern-panel ::-webkit-scrollbar {
    width: 8px;
    height: 8px;
}

#lantern-panel ::-webkit-scrollbar-track {
    background: var(--lantern-bg);
}

#lantern-panel ::-webkit-scrollbar-thumb {
    background: var(--lantern-bg-tertiary);
    border-radius: 4px;
}

#lantern-panel ::-webkit-scrollbar-thumb:hover {
    background: var(--lantern-border);
}

/* Resize handle */
#lantern-resize {
    position: absolute;
    top: 0;
    left: 0;
    right: 0;
    height: 4px;
    cursor: ns-resize;
    background: transparent;
}

#lantern-resize:hover {
    background: var(--lantern-accent);
}

/* Query Results Viewer */
.lantern-query-row {
    cursor: pointer;
}

.lantern-query-row:hover {
    background: var(--lantern-bg-secondary) !important;
}

.lantern-query-row.expanded {
    background: var(--lantern-bg-tertiary);
}

.lantern-query-expand {
    cursor: pointer;
    padding: 2px 8px;
    border-radius: 4px;
    background: var(--lantern-bg-tertiary);
    color: var(--lantern-text-muted);
    font-size: 10px;
    transition: all 0.2s;
}

.lantern-query-expand:hover {
    background: var(--lantern-accent);
    color: white;
}

.lantern-results-row {
    display: none;
}

.lantern-results-row.visible {
    display: table-row;
}

.lantern-results-container {
    padding: 12px;
    background: var(--lantern-bg);
    border-radius: 6px;
    margin: 8px 0;
    max-height: 300px;
    overflow: auto;
}

.lantern-results-header {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
    padding-bottom: 8px;
    border-bottom: 1px solid var(--lantern-border);
}

.lantern-results-title {
    font-weight: 600;
    color: var(--lantern-text);
}

.lantern-results-meta {
    font-size: 11px;
    color: var(--lantern-text-muted);
}

.lantern-results-meta .truncated {
    color: var(--lantern-warning);
}

.lantern-results-table {
    width: 100%;
    border-collapse: collapse;
    font-size: 11px;
}

.lantern-results-table th {
    background: var(--lantern-bg-secondary);
    padding: 6px 10px;
    text-align: left;
    font-weight: 600;
    color: var(--lantern-accent);
    border-bottom: 1px solid var(--lantern-border);
    position: sticky;
    top: 0;
}

.lantern-results-table td {
    padding: 6px 10px;
    border-bottom: 1px solid var(--lantern-border);
    max-width: 250px;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
}

.lantern-results-table tr:hover td {
    background: var(--lantern-bg-secondary);
}

.lantern-results-table td.null-value {
    color: var(--lantern-text-muted);
    font-style: italic;
}

.lantern-results-table td.number-value {
    color: var(--lantern-info);
}

.lantern-results-table td.boolean-value {
    color: var(--lantern-warning);
}

.lantern-insert-info {
    display: flex;
    gap: 16px;
    padding: 8px 12px;
    background: var(--lantern-bg);
    border-radius: 4px;
    font-size: 12px;
}

.lantern-insert-info .label {
    color: var(--lantern-text-muted);
}

.lantern-insert-info .value {
    color: var(--lantern-success);
    font-weight: 600;
}

.lantern-no-results {
    text-align: center;
    padding: 20px;
    color: var(--lantern-text-muted);
    font-style: italic;
}
</style>
]]
end

--------------------------------------------------------------------------------
-- JavaScript
--------------------------------------------------------------------------------

local function getScript(data)
    -- Safely encode data to JSON and escape for embedding in script tag
    local ok, jsonData = pcall(json.encode, data)
    if not ok then
        -- Fallback to minimal data if encoding fails
        jsonData = '{"error": "Failed to encode debug data", "duration": 0}'
    end
    -- Escape </script> sequences that would break the HTML
    jsonData = jsonData:gsub("</", "<\\/")
    -- Escape newlines and special chars in strings
    jsonData = jsonData:gsub("\\n", "\\\\n")

    return string.format([[
<script id="lantern-script">
(function() {
    'use strict';

    const data = %s;

    // State
    let isOpen = false;
    let isMaximized = false;
    let activeTab = 'request';

    // Icons
    const icons = {
        lantern: '<svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 2.38 1.19 4.47 3 5.74V17c0 .55.45 1 1 1h6c.55 0 1-.45 1-1v-2.26c1.81-1.27 3-3.36 3-5.74 0-3.87-3.13-7-7-7zm2 14h-4v-1h4v1zm0-2h-4v-1h4v1zm1.5-4.5c-.83 0-1.5-.67-1.5-1.5s.67-1.5 1.5-1.5 1.5.67 1.5 1.5-.67 1.5-1.5 1.5z"/></svg>',
        close: '<svg viewBox="0 0 24 24"><path d="M19 6.41L17.59 5 12 10.59 6.41 5 5 6.41 10.59 12 5 17.59 6.41 19 12 13.41 17.59 19 19 17.59 13.41 12z"/></svg>',
        maximize: '<svg viewBox="0 0 24 24"><path d="M7 14H5v5h5v-2H7v-3zm-2-4h2V7h3V5H5v5zm12 7h-3v2h5v-5h-2v3zM14 5v2h3v3h2V5h-5z"/></svg>',
        minimize: '<svg viewBox="0 0 24 24"><path d="M5 16h3v3h2v-5H5v2zm3-8H5v2h5V5H8v3zm6 11h2v-3h3v-2h-5v5zm2-11V5h-2v5h5V8h-3z"/></svg>',
    };

    // Format duration
    function formatDuration(ms) {
        if (ms < 1) return '<1ms';
        if (ms < 1000) return ms.toFixed(1) + 'ms';
        return (ms / 1000).toFixed(2) + 's';
    }

    // Format bytes
    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + ' B';
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
        return (bytes / (1024 * 1024)).toFixed(2) + ' MB';
    }

    // Escape HTML
    function escapeHtml(str) {
        if (typeof str !== 'string') return str;
        return str.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    }

    // Format JSON with syntax highlighting
    function formatJson(obj, indent = 0) {
        if (obj === null) return '<span class="lantern-json-null">null</span>';
        if (typeof obj === 'boolean') return '<span class="lantern-json-boolean">' + obj + '</span>';
        if (typeof obj === 'number') return '<span class="lantern-json-number">' + obj + '</span>';
        if (typeof obj === 'string') return '<span class="lantern-json-string">"' + escapeHtml(obj) + '"</span>';

        const spaces = '  '.repeat(indent);
        const nextSpaces = '  '.repeat(indent + 1);

        if (Array.isArray(obj)) {
            if (obj.length === 0) return '[]';
            const items = obj.map(item => nextSpaces + formatJson(item, indent + 1)).join(',\n');
            return '[\n' + items + '\n' + spaces + ']';
        }

        if (typeof obj === 'object') {
            const keys = Object.keys(obj);
            if (keys.length === 0) return '{}';
            const items = keys.map(key =>
                nextSpaces + '<span class="lantern-json-key">"' + escapeHtml(key) + '"</span>: ' + formatJson(obj[key], indent + 1)
            ).join(',\n');
            return '{\n' + items + '\n' + spaces + '}';
        }

        return String(obj);
    }

    // Create badge
    function createBadge() {
        const badge = document.createElement('div');
        badge.id = 'lantern-badge';
        badge.innerHTML = icons.lantern;

        // Show error count if any
        const errorCount = (data.logCounts?.error || 0) + (data.templates?.errors?.length || 0);
        if (errorCount > 0) {
            const info = document.createElement('span');
            info.id = 'lantern-badge-info';
            info.textContent = errorCount;
            badge.appendChild(info);
        }

        badge.addEventListener('click', togglePanel);
        document.body.appendChild(badge);
    }

    // Create panel
    function createPanel() {
        const panel = document.createElement('div');
        panel.id = 'lantern-panel';

        // Resize handle
        const resize = document.createElement('div');
        resize.id = 'lantern-resize';
        panel.appendChild(resize);

        // Header
        const header = document.createElement('div');
        header.id = 'lantern-header';
        header.innerHTML = `
            <div id="lantern-title">
                ${icons.lantern}
                <span>Lantern</span>
            </div>
            <div id="lantern-summary">
                <div class="lantern-summary-item ${getStatusClass(data.response?.status)}">
                    <span class="lantern-method ${data.request?.method}">${data.request?.method || 'GET'}</span>
                    <span>${data.response?.status || 200}</span>
                </div>
                <div class="lantern-summary-item info">
                    ${formatDuration(data.duration || 0)}
                </div>
                <div class="lantern-summary-item">
                    ${formatBytes(data.memory?.delta * 1024 || 0)}
                </div>
            </div>
            <div id="lantern-controls">
                <button class="lantern-btn" id="lantern-maximize" title="Maximize">${icons.maximize}</button>
                <button class="lantern-btn" id="lantern-close" title="Close">${icons.close}</button>
            </div>
        `;
        panel.appendChild(header);

        // Tabs
        const tabs = document.createElement('div');
        tabs.id = 'lantern-tabs';
        tabs.innerHTML = createTabs();
        panel.appendChild(tabs);

        // Content
        const content = document.createElement('div');
        content.id = 'lantern-content';
        content.innerHTML = createTabContents();
        panel.appendChild(content);

        document.body.appendChild(panel);

        // Event listeners
        document.getElementById('lantern-close').addEventListener('click', togglePanel);
        document.getElementById('lantern-maximize').addEventListener('click', toggleMaximize);

        tabs.querySelectorAll('.lantern-tab').forEach(tab => {
            tab.addEventListener('click', () => switchTab(tab.dataset.tab));
        });

        // Resize functionality
        setupResize(resize, panel);
    }

    function getStatusClass(status) {
        if (!status) return 'info';
        if (status >= 500) return 'error';
        if (status >= 400) return 'warning';
        if (status >= 300) return 'info';
        return 'success';
    }

    function createTabs() {
        const tabsConfig = [
            { id: 'request', label: 'Request', badge: null },
            { id: 'response', label: 'Response', badge: null },
            { id: 'templates', label: 'Templates', badge: data.templates?.renders?.length || 0 },
            { id: 'logs', label: 'Logs', badge: data.logs?.length || 0, error: data.logCounts?.error > 0 },
            { id: 'queries', label: 'Queries', badge: data.queryCount || 0 },
            { id: 'performance', label: 'Performance', badge: null },
        ];

        return tabsConfig.map(tab => {
            const badgeClass = tab.error ? 'error' : '';
            const badge = tab.badge !== null ? `<span class="lantern-tab-badge ${badgeClass}">${tab.badge}</span>` : '';
            return `<button class="lantern-tab ${tab.id === activeTab ? 'active' : ''}" data-tab="${tab.id}">${tab.label}${badge}</button>`;
        }).join('');
    }

    function createTabContents() {
        return `
            <div class="lantern-tab-content ${activeTab === 'request' ? 'active' : ''}" data-content="request">
                ${createRequestContent()}
            </div>
            <div class="lantern-tab-content ${activeTab === 'response' ? 'active' : ''}" data-content="response">
                ${createResponseContent()}
            </div>
            <div class="lantern-tab-content ${activeTab === 'templates' ? 'active' : ''}" data-content="templates">
                ${createTemplatesContent()}
            </div>
            <div class="lantern-tab-content ${activeTab === 'logs' ? 'active' : ''}" data-content="logs">
                ${createLogsContent()}
            </div>
            <div class="lantern-tab-content ${activeTab === 'queries' ? 'active' : ''}" data-content="queries">
                ${createQueriesContent()}
            </div>
            <div class="lantern-tab-content ${activeTab === 'performance' ? 'active' : ''}" data-content="performance">
                ${createPerformanceContent()}
            </div>
        `;
    }

    function createRequestContent() {
        const req = data.request || {};
        let html = '<div class="lantern-section">';
        html += '<div class="lantern-section-title">General</div>';
        html += '<table class="lantern-table">';
        html += `<tr><td class="key">Method</td><td class="value"><span class="lantern-method ${req.method}">${req.method || 'GET'}</span></td></tr>`;
        html += `<tr><td class="key">Path</td><td class="value">${escapeHtml(req.path || '/')}</td></tr>`;
        html += `<tr><td class="key">Full URL</td><td class="value">${escapeHtml(req.fullUrl || req.path || '/')}</td></tr>`;
        html += `<tr><td class="key">IP Address</td><td class="value">${escapeHtml(req.ip || 'unknown')}</td></tr>`;
        html += `<tr><td class="key">Protocol</td><td class="value">${req.protocol || 'http'}${req.secure ? ' (secure)' : ''}</td></tr>`;
        html += `<tr><td class="key">Hostname</td><td class="value">${escapeHtml(req.hostname || 'localhost')}</td></tr>`;
        html += `<tr><td class="key">XHR</td><td class="value">${req.xhr ? 'Yes' : 'No'}</td></tr>`;
        html += '</table></div>';

        // Headers
        html += '<div class="lantern-section">';
        html += '<div class="lantern-section-title">Headers</div>';
        html += '<table class="lantern-table">';
        const headers = req.headers || {};
        for (const [key, value] of Object.entries(headers)) {
            html += `<tr><td class="key">${escapeHtml(key)}</td><td class="value">${escapeHtml(value)}</td></tr>`;
        }
        if (Object.keys(headers).length === 0) {
            html += '<tr><td colspan="2" class="lantern-empty">No headers</td></tr>';
        }
        html += '</table></div>';

        // Query params
        if (req.query && Object.keys(req.query).length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Query Parameters</div>';
            html += '<table class="lantern-table">';
            for (const [key, value] of Object.entries(req.query)) {
                html += `<tr><td class="key">${escapeHtml(key)}</td><td class="value">${escapeHtml(value)}</td></tr>`;
            }
            html += '</table></div>';
        }

        // Route params
        if (req.params && Object.keys(req.params).length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Route Parameters</div>';
            html += '<table class="lantern-table">';
            for (const [key, value] of Object.entries(req.params)) {
                html += `<tr><td class="key">${escapeHtml(key)}</td><td class="value">${escapeHtml(value)}</td></tr>`;
            }
            html += '</table></div>';
        }

        // Body
        if (req.body && req.bodySize > 0) {
            html += '<div class="lantern-section">';
            html += `<div class="lantern-section-title">Body (${formatBytes(req.bodySize)})</div>`;
            if (req.parsedBody) {
                html += `<pre class="lantern-code lantern-json">${formatJson(req.parsedBody)}</pre>`;
            } else {
                html += `<pre class="lantern-code">${escapeHtml(req.body)}</pre>`;
            }
            html += '</div>';
        }

        // Cookies
        if (req.cookies && Object.keys(req.cookies).length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Cookies</div>';
            html += '<table class="lantern-table">';
            for (const [key, value] of Object.entries(req.cookies)) {
                html += `<tr><td class="key">${escapeHtml(key)}</td><td class="value">${escapeHtml(value)}</td></tr>`;
            }
            html += '</table></div>';
        }

        return html;
    }

    function createResponseContent() {
        const res = data.response || {};
        let html = '<div class="lantern-section">';
        html += '<div class="lantern-section-title">General</div>';
        html += '<table class="lantern-table">';
        html += `<tr><td class="key">Status</td><td class="value"><span class="lantern-status ${getStatusClass(res.status)}">${res.status || 200} ${res.statusText || 'OK'}</span></td></tr>`;
        html += `<tr><td class="key">Content-Type</td><td class="value">${escapeHtml(res.contentType || 'text/html')}</td></tr>`;
        html += `<tr><td class="key">Body Size</td><td class="value">${formatBytes(res.bodySize || 0)}</td></tr>`;
        html += '</table></div>';

        // Headers
        html += '<div class="lantern-section">';
        html += '<div class="lantern-section-title">Headers</div>';
        html += '<table class="lantern-table">';
        const headers = res.headers || {};
        for (const [key, value] of Object.entries(headers)) {
            html += `<tr><td class="key">${escapeHtml(key)}</td><td class="value">${escapeHtml(value)}</td></tr>`;
        }
        if (Object.keys(headers).length === 0) {
            html += '<tr><td colspan="2" class="lantern-empty">No headers set</td></tr>';
        }
        html += '</table></div>';

        return html;
    }

    function createTemplatesContent() {
        const tpl = data.templates || {};
        let html = '';

        // Stats
        html += '<div class="lantern-stats">';
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${tpl.totalRenders || 0}</div><div class="lantern-stat-label">Renders</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${formatDuration(tpl.totalTime || 0)}</div><div class="lantern-stat-label">Total Time</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${(tpl.cacheHitRate || 0).toFixed(0)}%%</div><div class="lantern-stat-label">Cache Hit Rate</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${(tpl.errors?.length || 0)}</div><div class="lantern-stat-label">Errors</div></div>`;
        html += '</div>';

        // Renders
        if (tpl.renders && tpl.renders.length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Template Renders</div>';
            html += '<table class="lantern-table">';
            html += '<thead><tr><th>Template</th><th>Count</th><th>Total Time</th><th>Avg Time</th><th>Max Time</th></tr></thead>';
            html += '<tbody>';
            for (const r of tpl.renders) {
                html += `<tr>
                    <td class="key">${escapeHtml(r.name)}</td>
                    <td>${r.count}</td>
                    <td>${formatDuration(r.totalTime)}</td>
                    <td>${formatDuration(r.avgTime)}</td>
                    <td>${formatDuration(r.maxTime)}</td>
                </tr>`;
            }
            html += '</tbody></table></div>';
        }

        // Errors
        if (tpl.errors && tpl.errors.length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Template Errors</div>';
            for (const err of tpl.errors) {
                html += `<div class="lantern-log error">
                    <span class="lantern-log-level">ERROR</span>
                    <span class="lantern-log-message">${escapeHtml(err.name)}: ${escapeHtml(err.error)}</span>
                </div>`;
            }
            html += '</div>';
        }

        // Filter usage
        if (tpl.filterUsage && tpl.filterUsage.length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Filter Usage</div>';
            html += '<table class="lantern-table">';
            html += '<thead><tr><th>Filter</th><th>Usage Count</th></tr></thead>';
            html += '<tbody>';
            for (const f of tpl.filterUsage) {
                html += `<tr><td class="key">${escapeHtml(f.name)}</td><td>${f.count}</td></tr>`;
            }
            html += '</tbody></table></div>';
        }

        if (!tpl.renders?.length && !tpl.errors?.length) {
            html += '<div class="lantern-empty"><div class="lantern-empty-icon">&#128196;</div>No template renders recorded.<br>Enable metrics in Vein: <code>vein.new({ metrics = true })</code></div>';
        }

        return html;
    }

    function createLogsContent() {
        const logs = Array.isArray(data.logs) ? data.logs : [];

        if (logs.length === 0) {
            return '<div class="lantern-empty"><div class="lantern-empty-icon">&#128221;</div>No logs recorded.<br>Use <code>lantern:log(level, message)</code> to add logs.</div>';
        }

        let html = '<div class="lantern-section">';
        for (const log of logs) {
            const context = log.context ? `<pre class="lantern-code">${formatJson(log.context)}</pre>` : '';
            html += `<div class="lantern-log ${log.level}">
                <span class="lantern-log-time">+${formatDuration(log.time * 1000)}</span>
                <span class="lantern-log-level">${log.level}</span>
                <div class="lantern-log-message">${escapeHtml(log.message)}${context}</div>
            </div>`;
        }
        html += '</div>';

        return html;
    }

    // Format SQL with syntax highlighting
    function formatSql(sql) {
        if (!sql) return '';
        let escaped = escapeHtml(sql);

        // Highlight SQL keywords
        const keywords = ['SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'INSERT', 'INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE', 'CREATE', 'TABLE', 'DROP', 'ALTER', 'ADD', 'INDEX', 'JOIN', 'LEFT', 'RIGHT', 'INNER', 'OUTER', 'ON', 'AS', 'ORDER', 'BY', 'GROUP', 'HAVING', 'LIMIT', 'OFFSET', 'DISTINCT', 'COUNT', 'SUM', 'AVG', 'MIN', 'MAX', 'IN', 'NOT', 'NULL', 'IS', 'LIKE', 'BETWEEN', 'ASC', 'DESC', 'PRAGMA', 'BEGIN', 'COMMIT', 'ROLLBACK', 'PRIMARY', 'KEY', 'FOREIGN', 'REFERENCES', 'DEFAULT', 'UNIQUE', 'CONSTRAINT', 'IF', 'EXISTS', 'CASCADE', 'AUTOINCREMENT'];

        // Match keywords as whole words
        keywords.forEach(kw => {
            const regex = new RegExp('\\b(' + kw + ')\\b', 'gi');
            escaped = escaped.replace(regex, '<span class="lantern-sql-keyword">$1</span>');
        });

        // Highlight string literals
        escaped = escaped.replace(/'([^']*)'/g, '<span class="lantern-sql-string">\'$1\'</span>');

        // Highlight numbers
        escaped = escaped.replace(/\b(\d+)\b/g, '<span class="lantern-sql-number">$1</span>');

        // Highlight placeholders (?)
        escaped = escaped.replace(/\?/g, '<span class="lantern-sql-param">?</span>');

        return escaped;
    }

    function createQueriesContent() {
        const queries = Array.isArray(data.queries) ? data.queries : [];
        const stats = data.queryStats || { total: queries.length, totalTime: data.totalQueryTime || 0, byType: {} };

        if (queries.length === 0) {
            return '<div class="lantern-empty"><div class="lantern-empty-icon">&#128451;</div>No database queries recorded.<br>Use <code>lantern.freight(db)</code> to track Freight queries<br>or <code>req.lantern:recordQuery(sql, params, duration)</code> manually.</div>';
        }

        // Calculate average and find slowest
        const avgTime = queries.length > 0 ? (data.totalQueryTime || 0) / queries.length : 0;
        let slowestQuery = null;
        let slowestTime = 0;
        queries.forEach(q => {
            if (q.duration > slowestTime) {
                slowestTime = q.duration;
                slowestQuery = q;
            }
        });

        // Stats
        let html = '<div class="lantern-stats">';
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${queries.length}</div><div class="lantern-stat-label">Total Queries</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${formatDuration(data.totalQueryTime || 0)}</div><div class="lantern-stat-label">Total Time</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${formatDuration(avgTime)}</div><div class="lantern-stat-label">Avg Time</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${formatDuration(slowestTime)}</div><div class="lantern-stat-label">Slowest</div></div>`;
        html += '</div>';

        // Query type breakdown
        const byType = stats.byType || {};
        if (Object.keys(byType).length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Query Types</div>';
            html += '<div style="display: flex; gap: 8px; flex-wrap: wrap; margin-bottom: 16px;">';
            for (const [type, count] of Object.entries(byType)) {
                html += `<span class="lantern-query-type ${type}">${type}: ${count}</span>`;
            }
            html += '</div></div>';
        }

        // Query list
        html += '<div class="lantern-section">';
        html += '<div class="lantern-section-title">Query Log</div>';
        html += '<table class="lantern-table">';
        html += '<thead><tr><th style="width:40px">#</th><th style="width:70px">Type</th><th>Query</th><th style="width:80px">Duration</th><th style="width:60px">Rows</th><th style="width:80px">Results</th></tr></thead>';
        html += '<tbody>';

        for (let i = 0; i < queries.length; i++) {
            const q = queries[i];
            const isSlow = q.duration > avgTime * 2 && q.duration > 10; // Slow if 2x average and > 10ms
            const rowClass = isSlow ? 'lantern-query-slow' : '';
            const qType = q.type || 'UNKNOWN';
            const queryId = 'query-' + i;

            let paramsHtml = '';
            if (q.params && Array.isArray(q.params) && q.params.length > 0) {
                paramsHtml = '<br><small style="color: var(--lantern-text-muted);">Params: [' + q.params.map(p => escapeHtml(JSON.stringify(p))).join(', ') + ']</small>';
            }

            // Determine if results are available
            const hasResults = q.results && q.results.rows && q.results.rows.length > 0;
            const hasInsertId = q.lastInsertId != null;

            let resultsBtn = '';
            if (hasResults) {
                resultsBtn = `<span class="lantern-query-expand" onclick="window.lanternToggleResults('${queryId}')" title="View ${q.results.totalRows} row(s)">&#128065; View</span>`;
            } else if (hasInsertId) {
                resultsBtn = `<span class="lantern-query-expand" onclick="window.lanternToggleResults('${queryId}')" title="View insert info">&#128065; Info</span>`;
            } else if (qType === 'SELECT') {
                resultsBtn = '<span style="color: var(--lantern-text-muted); font-size: 10px;">Empty</span>';
            } else {
                resultsBtn = '<span style="color: var(--lantern-text-muted); font-size: 10px;">-</span>';
            }

            html += `<tr class="${rowClass} lantern-query-row" id="${queryId}-row">
                <td style="color: var(--lantern-text-muted);">${q.index || i + 1}</td>
                <td><span class="lantern-query-type ${qType}">${qType}</span></td>
                <td><code style="white-space: pre-wrap; word-break: break-all;">${formatSql(q.query)}</code>${paramsHtml}</td>
                <td${isSlow ? ' style="color: var(--lantern-error); font-weight: 600;"' : ''}>${formatDuration(q.duration)}</td>
                <td>${q.rowCount ?? '-'}</td>
                <td>${resultsBtn}</td>
            </tr>`;

            // Results row (hidden by default)
            if (hasResults || hasInsertId) {
                html += `<tr class="lantern-results-row" id="${queryId}-results">
                    <td colspan="6" style="padding: 0;">
                        <div class="lantern-results-container">`;

                if (hasResults) {
                    const r = q.results;
                    html += `<div class="lantern-results-header">
                        <span class="lantern-results-title">Query Results</span>
                        <span class="lantern-results-meta">
                            Showing ${r.rows.length} of ${r.totalRows} rows
                            ${r.truncated ? '<span class="truncated">(truncated)</span>' : ''}
                        </span>
                    </div>`;

                    if (r.columns && r.columns.length > 0) {
                        html += '<table class="lantern-results-table"><thead><tr>';
                        for (const col of r.columns) {
                            html += `<th>${escapeHtml(col)}</th>`;
                        }
                        html += '</tr></thead><tbody>';

                        for (const row of r.rows) {
                            html += '<tr>';
                            for (const col of r.columns) {
                                const val = row[col];
                                let cellClass = '';
                                let cellValue = '';

                                if (val === null || val === undefined) {
                                    cellClass = 'null-value';
                                    cellValue = 'NULL';
                                } else if (typeof val === 'number') {
                                    cellClass = 'number-value';
                                    cellValue = String(val);
                                } else if (typeof val === 'boolean') {
                                    cellClass = 'boolean-value';
                                    cellValue = String(val);
                                } else {
                                    cellValue = escapeHtml(String(val));
                                }

                                html += `<td class="${cellClass}" title="${escapeHtml(String(val))}">${cellValue}</td>`;
                            }
                            html += '</tr>';
                        }
                        html += '</tbody></table>';
                    }
                } else if (hasInsertId) {
                    html += `<div class="lantern-insert-info">
                        <div><span class="label">Last Insert ID:</span> <span class="value">${q.lastInsertId}</span></div>
                        <div><span class="label">Affected Rows:</span> <span class="value">${q.rowCount ?? '-'}</span></div>
                    </div>`;
                }

                html += '</div></td></tr>';
            }
        }
        html += '</tbody></table></div>';

        return html;
    }

    // Toggle results visibility
    window.lanternToggleResults = function(queryId) {
        const resultsRow = document.getElementById(queryId + '-results');
        const queryRow = document.getElementById(queryId + '-row');
        if (resultsRow) {
            resultsRow.classList.toggle('visible');
            if (queryRow) {
                queryRow.classList.toggle('expanded');
            }
        }
    };

    function createPerformanceContent() {
        let html = '';

        // Summary stats
        html += '<div class="lantern-stats">';
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${formatDuration(data.duration || 0)}</div><div class="lantern-stat-label">Total Time</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${formatBytes((data.memory?.delta || 0) * 1024)}</div><div class="lantern-stat-label">Memory Delta</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${formatBytes((data.memory?.peak || 0) * 1024)}</div><div class="lantern-stat-label">Peak Memory</div></div>`;
        html += `<div class="lantern-stat"><div class="lantern-stat-value">${data.luaVersion || 'Lua 5.4'}</div><div class="lantern-stat-label">Lua Version</div></div>`;
        html += '</div>';

        // Timeline
        if (data.timeline && data.timeline.length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Timeline</div>';
            html += '<div class="lantern-timeline">';
            for (const event of data.timeline) {
                html += `<div class="lantern-timeline-item">
                    <div class="lantern-timeline-time">+${formatDuration(event.time * 1000)}</div>
                    <div class="lantern-timeline-label">${escapeHtml(event.label)}</div>
                </div>`;
            }
            html += '</div></div>';
        }

        // Middleware
        if (data.middlewares && data.middlewares.length > 0) {
            html += '<div class="lantern-section">';
            html += '<div class="lantern-section-title">Middleware Execution</div>';
            html += '<table class="lantern-table">';
            html += '<thead><tr><th>Middleware</th><th>Duration</th></tr></thead>';
            html += '<tbody>';
            for (const mw of data.middlewares) {
                html += `<tr><td class="key">${escapeHtml(mw.name)}</td><td>${formatDuration(mw.duration)}</td></tr>`;
            }
            html += '</tbody></table></div>';
        }

        // Memory details
        html += '<div class="lantern-section">';
        html += '<div class="lantern-section-title">Memory Details</div>';
        html += '<table class="lantern-table">';
        html += `<tr><td class="key">Start</td><td class="value">${formatBytes((data.memory?.start || 0) * 1024)}</td></tr>`;
        html += `<tr><td class="key">End</td><td class="value">${formatBytes((data.memory?.end || 0) * 1024)}</td></tr>`;
        html += `<tr><td class="key">Peak</td><td class="value">${formatBytes((data.memory?.peak || 0) * 1024)}</td></tr>`;
        html += `<tr><td class="key">Delta</td><td class="value">${formatBytes((data.memory?.delta || 0) * 1024)}</td></tr>`;
        html += '</table></div>';

        return html;
    }

    function togglePanel() {
        const panel = document.getElementById('lantern-panel');
        const badge = document.getElementById('lantern-badge');

        if (!panel || !badge) {
            console.error('[Lantern] Panel or badge not found');
            return;
        }

        isOpen = !isOpen;

        if (isOpen) {
            panel.classList.add('open');
            badge.style.display = 'none';
        } else {
            panel.classList.remove('open');
            panel.classList.remove('maximized');
            isMaximized = false;
            badge.style.display = 'flex';
        }
    }

    function toggleMaximize() {
        isMaximized = !isMaximized;
        const panel = document.getElementById('lantern-panel');
        const btn = document.getElementById('lantern-maximize');

        if (isMaximized) {
            panel.classList.add('maximized');
            btn.innerHTML = icons.minimize;
        } else {
            panel.classList.remove('maximized');
            btn.innerHTML = icons.maximize;
        }
    }

    function switchTab(tabId) {
        activeTab = tabId;

        document.querySelectorAll('.lantern-tab').forEach(tab => {
            tab.classList.toggle('active', tab.dataset.tab === tabId);
        });

        document.querySelectorAll('.lantern-tab-content').forEach(content => {
            content.classList.toggle('active', content.dataset.content === tabId);
        });
    }

    function setupResize(handle, panel) {
        let startY, startHeight;

        handle.addEventListener('mousedown', (e) => {
            startY = e.clientY;
            startHeight = panel.offsetHeight;
            document.addEventListener('mousemove', onMouseMove);
            document.addEventListener('mouseup', onMouseUp);
            e.preventDefault();
        });

        function onMouseMove(e) {
            const delta = startY - e.clientY;
            const newHeight = Math.min(Math.max(startHeight + delta, 200), window.innerHeight * 0.9);
            panel.style.height = newHeight + 'px';
        }

        function onMouseUp() {
            document.removeEventListener('mousemove', onMouseMove);
            document.removeEventListener('mouseup', onMouseUp);
        }
    }

    // Keyboard shortcut (Ctrl+Shift+L)
    document.addEventListener('keydown', (e) => {
        if (e.ctrlKey && e.shiftKey && e.key === 'L') {
            togglePanel();
            e.preventDefault();
        }
        if (e.key === 'Escape' && isOpen) {
            togglePanel();
        }
    });

    // Initialize
    function init() {
        try {
            createBadge();
        } catch (e) {
            console.error('[Lantern] Error creating badge:', e);
        }
        try {
            createPanel();
        } catch (e) {
            console.error('[Lantern] Error creating panel:', e);
        }
    }

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
</script>
]], jsonData)
end

--------------------------------------------------------------------------------
-- Panel Generation
--------------------------------------------------------------------------------

--- Generate the full panel HTML to inject
---@param data table Collected debug data
---@return string HTML to inject before </body>
function panel.generate(data)
    local ok, result = pcall(function()
        local html = {}

        -- Add styles
        table.insert(html, getStyles())

        -- Add script with data
        table.insert(html, getScript(data))

        return table.concat(html, "\n")
    end)

    if ok then
        return result
    else
        -- Return a minimal error indicator if generation fails
        return '<!-- Lantern: Error generating panel: ' .. tostring(result):gsub("%-%-", "- -") .. ' -->'
    end
end

--- Inject panel into HTML response
---@param html string Original HTML
---@param data table Collected debug data
---@return string Modified HTML with panel injected
function panel.inject(html, data)
    local ok, panelHtml = pcall(panel.generate, data)
    if not ok then
        panelHtml = '<!-- Lantern: Error: ' .. tostring(panelHtml):gsub("%-%-", "- -") .. ' -->'
    end

    -- Try to inject before </body>
    -- Use a function to avoid % being interpreted as pattern replacement
    local injected = html:gsub("</body>", function()
        return panelHtml .. "</body>"
    end)

    -- If no </body> found, append at the end
    if injected == html then
        injected = html .. panelHtml
    end

    return injected
end

return panel
