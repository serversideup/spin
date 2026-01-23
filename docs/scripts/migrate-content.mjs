#!/usr/bin/env node
/**
 * Content Migration Script for Nuxt Content v2 to v3
 *
 * Transforms:
 * - ::code-panel with label → fenced code blocks with [label] syntax
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

function migrateFile(filePath) {
    let content = readFileSync(filePath, 'utf-8');
    const originalContent = content;

    // Apply migrations
    content = migrateCodePanel(content);
    content = migrateCodePanelSimple(content);

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
