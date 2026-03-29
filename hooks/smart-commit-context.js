#!/usr/bin/env node
/**
 * smart-commit-context.js
 * UserPromptSubmit hook — injects staged file context when user asks to commit.
 *
 * Registered in: ~/.claude/settings.json
 * Event: UserPromptSubmit
 *
 * Input (stdin): JSON { prompt, session_id, cwd, ... }
 * Output (stdout): JSON { continue, hookSpecificOutput? }
 */

const { execSync } = require('child_process');

let input = '';
process.stdin.on('data', (chunk) => { input += chunk; });

process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input || '{}');
    const prompt = (data.prompt || '').toLowerCase();

    // Keywords that indicate a commit-related request
    const commitKeywords = [
      'commit', 'smart commit',
      'stage', 'git add', 'git commit',
      'push', 'staged changes', 'analyze changes'
    ];

    const isCommitRelated = commitKeywords.some((kw) => prompt.includes(kw));

    if (!isCommitRelated) {
      process.stdout.write(JSON.stringify({ continue: true }));
      return;
    }

    // Use the cwd provided by Claude Code, or process.cwd() as fallback
    const workDir = data.cwd || process.cwd();
    const execOpts = { encoding: 'utf8', cwd: workDir };

    // Verify we're in a git repo
    try {
      execSync('git rev-parse --is-inside-work-tree', { ...execOpts, stdio: 'pipe' });
    } catch {
      process.stdout.write(JSON.stringify({ continue: true }));
      return;
    }

    // Get staged files
    let stagedFiles = '';
    try {
      stagedFiles = execSync('git diff --staged --name-only', execOpts).trim();
    } catch {
      // ignore
    }

    if (!stagedFiles) {
      // No staged files — still useful to inject unstaged status
      let statusOutput = '';
      try {
        statusOutput = execSync('git status --short', execOpts).trim();
      } catch {
        // ignore
      }

      const context = statusOutput
        ? `## Git Context (smart-commit hook)\n\n⚠️ No files are staged yet.\n\n### Working Tree Status\n\`\`\`\n${statusOutput}\n\`\`\``
        : `## Git Context (smart-commit hook)\n\n⚠️ No files are staged and the working tree is clean.`;

      process.stdout.write(JSON.stringify({
        continue: true,
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          additionalContext: context,
        },
      }));
      return;
    }

    // Get change statistics
    let stagedStat = '';
    try {
      stagedStat = execSync('git diff --staged --stat', execOpts).trim();
    } catch {
      // ignore
    }

    // Get abbreviated diff (cap at 4000 chars to avoid flooding context)
    let stagedDiff = '';
    try {
      const fullDiff = execSync('git diff --staged', execOpts).trim();
      stagedDiff = fullDiff.length > 4000
        ? fullDiff.slice(0, 4000) + '\n\n... (diff truncated — run `git diff --staged` to see the rest)'
        : fullDiff;
    } catch {
      // ignore
    }

    // Get recent commits for style reference
    let recentCommits = '';
    try {
      recentCommits = execSync('git log --oneline -5', execOpts).trim();
    } catch {
      // ignore
    }

    // Build the context block injected into Claude's prompt
    const context = [
      '## Git Context (auto-injected by smart-commit hook)',
      '',
      `### Staged Files (${stagedFiles.split('\n').length} files)`,
      '```',
      stagedFiles,
      '```',
      '',
      '### Change Statistics',
      '```',
      stagedStat,
      '```',
      '',
      '### Staged Diff',
      '```diff',
      stagedDiff,
      '```',
      '',
      '### Recent Commits (style reference)',
      '```',
      recentCommits || '(no commits yet)',
      '```',
    ].join('\n');

    process.stdout.write(JSON.stringify({
      continue: true,
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        additionalContext: context,
      },
    }));

  } catch (err) {
    // On any error, don't block Claude — just continue without extra context
    process.stdout.write(JSON.stringify({ continue: true }));
  }
});
