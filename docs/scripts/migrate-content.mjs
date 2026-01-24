#!/usr/bin/env node
/**
 * Content Migration Script for Nuxt Content v2 to v3
 *
 * Transforms:
 * - ::code-panel with label → fenced code blocks with [label] syntax
 * - Removes duplicate H1 headers (title is now rendered by UPageHeader from frontmatter)
 * - Adds {target="_blank"} to external links (https://) for new tab behavior
 * - Replaces backticks with double quotes in code block labels (e.g., [Install `spin`] → [Install "spin"])
 * - Keeps ::note and ::lead-p as-is (custom components still work)
 */

import { readFileSync, writeFileSync, readdirSync, statSync } from 'fs';
import { join, extname } from 'path';

const CONTENT_DIR = join(process.cwd(), 'content');

function getAllMarkdownFiles(dir, files = []) {
    const items = readdirSync(dir);

    for (const item of items) {
        const fullPath = join(dir, item);
        const stat = statSync(fullPath);

        if (stat.isDirectory()) {
            getAllMarkdownFiles(fullPath, files);
        } else if (extname(item) === '.md') {
            files.push(fullPath);
        }
    }

    return files;
}

function migrateCodePanel(content) {
    // Pattern to match ::code-panel blocks
    // This handles:
    // ::code-panel
    // ---
    // label: Some label
    // ---
    // ```language
    // code
    // ```
    // ::

    const codePanelRegex = /::code-panel\s*\n---\s*\nlabel:\s*(.+?)\s*\n---\s*\n(```\w*\n[\s\S]*?\n```)\s*\n::/g;

    return content.replace(codePanelRegex, (match, label, codeBlock) => {
        // Extract the language from the code block
        const languageMatch = codeBlock.match(/^```(\w*)/);
        const language = languageMatch ? languageMatch[1] : '';

        // Get the code content (without the opening and closing ```)
        const codeContent = codeBlock.replace(/^```\w*\n/, '').replace(/\n```$/, '');

        // Return the new format with [label]
        return `\`\`\`${language} [${label}]\n${codeContent}\n\`\`\``;
    });
}

function migrateCodePanelSimple(content) {
    // Handle code-panel without label (simpler case)
    const simpleCodePanelRegex = /::code-panel\s*\n(```\w*\n[\s\S]*?\n```)\s*\n::/g;

    return content.replace(simpleCodePanelRegex, (match, codeBlock) => {
        return codeBlock;
    });
}

function removeDuplicateH1(content) {
    // In Nuxt UI Pro, UPageHeader renders the title from frontmatter,
    // so we need to remove duplicate H1 headers from the markdown body.
    //
    // Pattern: After frontmatter (---...---), remove the first H1 that matches
    // or is similar to the frontmatter title.

    // Split content into frontmatter and body
    const frontmatterMatch = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
    if (!frontmatterMatch) {
        return content;
    }

    const frontmatter = frontmatterMatch[1];
    let body = frontmatterMatch[2];

    // Extract title from frontmatter
    const titleMatch = frontmatter.match(/^title:\s*['"]?(.+?)['"]?\s*$/m);
    if (!titleMatch) {
        return content;
    }

    // Remove the first H1 header from the body (it duplicates the frontmatter title)
    // Match: # Title (with optional emoji) followed by newline
    body = body.replace(/^\s*#\s+.+?\n/, '\n');

    return `---\n${frontmatter}\n---\n${body}`;
}

function addExternalLinkTargets(content) {
    // Add {target="_blank"} to external links (https://) that don't already have attributes
    // Pattern: [text](https://...) not followed by {
    // This follows Nuxt Content's markdown extended syntax

    return content.replace(
        /\[([^\]]+)\]\((https?:\/\/[^)]+)\)(?!\{)/g,
        '[$1]($2){target="_blank"}'
    );
}

function fixCodeBlockLabels(content) {
    // Replace backticks with double quotes inside code block labels
    // Pattern: ```lang [label with `backticks`]
    // Becomes: ```lang [label with "quotes"]

    return content.replace(
        /^(```\w*\s*\[)([^\]]*`[^\]]*)\]/gm,
        (match, prefix, label) => {
            // Replace all backticks with double quotes in the label
            const fixedLabel = label.replace(/`/g, '"');
            return `${prefix}${fixedLabel}]`;
        }
    );
}

function migrateFile(filePath) {
    let content = readFileSync(filePath, 'utf-8');
    const originalContent = content;

    // Apply migrations
    content = migrateCodePanel(content);
    content = migrateCodePanelSimple(content);
    content = removeDuplicateH1(content);
    content = addExternalLinkTargets(content);
    content = fixCodeBlockLabels(content);

    // Check if content was changed
    if (content !== originalContent) {
        writeFileSync(filePath, content, 'utf-8');
        return true;
    }

    return false;
}

function main() {
    console.log('Starting content migration...\n');

    const files = getAllMarkdownFiles(CONTENT_DIR);
    let migratedCount = 0;

    for (const file of files) {
        const relativePath = file.replace(CONTENT_DIR, '');
        const wasMigrated = migrateFile(file);

        if (wasMigrated) {
            console.log(`✓ Migrated: ${relativePath}`);
            migratedCount++;
        }
    }

    console.log(`\nMigration complete!`);
    console.log(`Files processed: ${files.length}`);
    console.log(`Files migrated: ${migratedCount}`);
}

main();
