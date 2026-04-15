#!/usr/bin/env python3
"""Import ChatGPT conversations into Oulala's brain.

Parses a ChatGPT data export (conversations.json), extracts personal
facts using Claude, and writes them to brain/people/ and brain/topics/.
"""

import json
import sys
import os
import subprocess
import argparse
from pathlib import Path
from datetime import datetime


def parse_export(filepath):
    with open(filepath) as f:
        data = json.load(f)
    if isinstance(data, dict) and "conversations" in data:
        return data["conversations"]
    if isinstance(data, list):
        return data
    raise ValueError("Unrecognized format — expected JSON array or {conversations: [...]}")


def extract_active_branch(conv):
    """Walk mapping tree from current_node up to root, return messages in order."""
    mapping = conv.get("mapping", {})
    current = conv.get("current_node")
    if not mapping or not current:
        return []

    chain = []
    node_id = current
    while node_id:
        node = mapping.get(node_id)
        if not node:
            break
        msg = node.get("message")
        if msg:
            role = msg.get("author", {}).get("role", "")
            content = msg.get("content", {})
            text = ""
            if isinstance(content, dict):
                parts = content.get("parts", [])
                text = " ".join(str(p) for p in parts if isinstance(p, str))
            elif isinstance(content, str):
                text = content
            if text.strip() and role in ("user", "assistant"):
                chain.append({"role": role, "text": text.strip()})
        node_id = node.get("parent")

    chain.reverse()
    return chain


def summarize_conv(conv, messages):
    title = conv.get("title", "Untitled")
    ts = conv.get("create_time")
    date = datetime.fromtimestamp(ts).strftime("%Y-%m-%d") if ts else "unknown"
    user_lines = [m["text"][:300] for m in messages if m["role"] == "user"][:5]
    return {"title": title, "date": date, "message_count": len(messages), "user_messages": user_lines}


def extract_facts(batch, batch_num, total_batches):
    print(f"  Analyzing batch {batch_num}/{total_batches} ({len(batch)} conversations)...")

    prompt = """Analyze these ChatGPT conversation summaries and extract facts about the USER.

CONVERSATIONS:
""" + json.dumps(batch, indent=2) + """

Output valid JSON with this exact structure:
{
  "people": [
    {"name": "Name", "details": ["relationship or context", "other fact"]}
  ],
  "preferences": ["specific preference"],
  "work": ["job or career fact"],
  "locations": ["lives in X"],
  "interests": ["hobby or interest"],
  "facts": ["other personal fact"]
}

Rules:
- Only facts about the USER, not the AI
- Be specific: "prefers dark roast coffee" not "has coffee preferences"
- Skip trivial/generic facts
- Empty arrays are fine
- Output ONLY valid JSON, no other text"""

    try:
        result = subprocess.run(
            ["claude", "-p", prompt],
            capture_output=True, text=True, timeout=180
        )
        if result.returncode != 0:
            print(f"    Warning: Claude returned exit code {result.returncode}", file=sys.stderr)
            return None

        text = result.stdout.strip()
        # Find the JSON object in the response
        depth = 0
        start = -1
        for i, c in enumerate(text):
            if c == "{":
                if depth == 0:
                    start = i
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0 and start >= 0:
                    return json.loads(text[start : i + 1])

    except subprocess.TimeoutExpired:
        print(f"    Warning: batch {batch_num} timed out", file=sys.stderr)
    except json.JSONDecodeError as e:
        print(f"    Warning: couldn't parse response — {e}", file=sys.stderr)
    except Exception as e:
        print(f"    Warning: batch {batch_num} failed — {e}", file=sys.stderr)

    return None


def merge_facts(all_facts):
    merged = {"people": {}, "preferences": set(), "work": set(),
              "locations": set(), "interests": set(), "facts": set()}

    for facts in all_facts:
        if not facts:
            continue
        for person in facts.get("people", []):
            name = person.get("name", "").strip()
            if not name:
                continue
            key = name.lower()
            if key not in merged["people"]:
                merged["people"][key] = {"name": name, "details": set()}
            for d in person.get("details", []):
                if d and d.strip():
                    merged["people"][key]["details"].add(d.strip())

        for field in ("preferences", "work", "locations", "interests", "facts"):
            for item in facts.get(field, []):
                if item and item.strip():
                    merged[field].add(item.strip())

    return merged


def write_brain_files(merged, brain_dir, dry_run=False):
    people_dir = brain_dir / "people"
    topics_dir = brain_dir / "topics"
    files_written = []
    index_additions = []

    # --- People ---
    if merged["people"]:
        if not dry_run:
            people_dir.mkdir(exist_ok=True)

        for key, person in sorted(merged["people"].items()):
            name = person["name"]
            slug = key.replace(" ", "-")
            filepath = people_dir / f"{slug}.md"
            details = sorted(person["details"])

            if dry_run:
                print(f"    brain/people/{slug}.md — {len(details)} facts")
            else:
                if filepath.exists():
                    existing = filepath.read_text()
                    new_details = [d for d in details if d not in existing]
                    if new_details:
                        with open(filepath, "a") as f:
                            for d in new_details:
                                f.write(f"- {d}\n")
                        files_written.append(f"people/{slug}.md (updated, +{len(new_details)})")
                else:
                    content = f"# {name}\n\n" + "".join(f"- {d}\n" for d in details)
                    filepath.write_text(content)
                    files_written.append(f"people/{slug}.md (created, {len(details)} facts)")

            summary = details[0][:60] if details else ""
            index_additions.append(f"- [{name}](people/{slug}.md) — {summary}")

    # --- Topics ---
    topic_map = [
        ("preferences", "Preferences"),
        ("work", "Work"),
        ("interests", "Interests"),
        ("locations", "Locations"),
        ("facts", "Other"),
    ]

    topics_created = []
    for field, title in topic_map:
        items = sorted(merged.get(field, set()))
        if not items:
            continue

        slug = field
        filepath = topics_dir / f"{slug}.md"

        if dry_run:
            print(f"    brain/topics/{slug}.md — {len(items)} items")
        else:
            topics_dir.mkdir(exist_ok=True)
            if filepath.exists():
                existing = filepath.read_text()
                new_items = [i for i in items if i not in existing]
                if new_items:
                    with open(filepath, "a") as f:
                        for i in new_items:
                            f.write(f"- {i}\n")
                    files_written.append(f"topics/{slug}.md (updated, +{len(new_items)})")
            else:
                content = f"# {title}\n\n" + "".join(f"- {i}\n" for i in items)
                filepath.write_text(content)
                files_written.append(f"topics/{slug}.md (created, {len(items)} items)")

        preview = ", ".join(items[:3])
        if len(items) > 3:
            preview += f" (+{len(items)-3} more)"
        topics_created.append(f"- [{title}](topics/{slug}.md) — {preview}")

    # --- Update MEMORY.md index ---
    if not dry_run and (index_additions or topics_created):
        memory_file = brain_dir / "MEMORY.md"
        import_block = "\n## Imported from ChatGPT\n\n"
        if index_additions:
            import_block += "### People\n" + "\n".join(index_additions) + "\n\n"
        if topics_created:
            import_block += "### Topics\n" + "\n".join(topics_created) + "\n"

        if memory_file.exists():
            existing = memory_file.read_text()
            if "## Imported from ChatGPT" not in existing:
                with open(memory_file, "a") as f:
                    f.write(import_block)
            # If section exists, don't duplicate — user can re-run after deleting it
        else:
            memory_file.write_text("# Memory Index\n" + import_block)

        files_written.append("MEMORY.md (updated index)")

    return files_written


def main():
    parser = argparse.ArgumentParser(description="Import ChatGPT conversations into Oulala brain")
    parser.add_argument("export_file", help="Path to conversations.json")
    parser.add_argument("--dry-run", action="store_true", help="Preview without writing files")
    parser.add_argument("--brain-dir", default=os.path.expanduser("~/.oulala/brain"))
    parser.add_argument("--batch-size", type=int, default=25, help="Conversations per batch (default: 25)")
    args = parser.parse_args()

    brain_dir = Path(args.brain_dir)
    export_file = Path(args.export_file)

    if not export_file.exists():
        print(f"Error: {export_file} not found")
        sys.exit(1)
    if not brain_dir.exists():
        print(f"Error: brain directory {brain_dir} not found")
        sys.exit(1)

    # Check claude CLI
    if not dry_run_only(args) and subprocess.run(["which", "claude"], capture_output=True).returncode != 0:
        print("Error: claude CLI not found. Install it first.")
        sys.exit(1)

    # 1. Parse
    print(f"Parsing {export_file.name}...")
    conversations = parse_export(str(export_file))
    print(f"  {len(conversations)} conversations found")

    # 2. Extract and summarize
    print("Processing conversations...")
    summaries = []
    skipped = 0
    for conv in conversations:
        messages = extract_active_branch(conv)
        if len(messages) < 3:
            skipped += 1
            continue
        summaries.append(summarize_conv(conv, messages))

    print(f"  {len(summaries)} usable, {skipped} skipped (too short)")

    if not summaries:
        print("Nothing to import.")
        sys.exit(0)

    # 3. Extract facts in batches
    print("Extracting personal facts with Claude...")
    batches = [summaries[i : i + args.batch_size] for i in range(0, len(summaries), args.batch_size)]
    all_facts = []

    for i, batch in enumerate(batches, 1):
        facts = extract_facts(batch, i, len(batches))
        if facts:
            all_facts.append(facts)

    if not all_facts:
        print("No facts could be extracted.")
        sys.exit(1)

    # 4. Merge
    print("Merging and deduplicating...")
    merged = merge_facts(all_facts)
    people_count = len(merged["people"])
    total_facts = sum(len(v) if isinstance(v, set) else len(v) for v in merged.values())
    print(f"  {people_count} people, {total_facts} total facts")

    # 5. Write
    if args.dry_run:
        print("\n--- DRY RUN (no files will be written) ---\n")
        write_brain_files(merged, brain_dir, dry_run=True)
        print("\nRun without --dry-run to apply.")
    else:
        print("\nWriting to brain/...")
        files = write_brain_files(merged, brain_dir)
        for f in files:
            print(f"  {f}")
        print(f"\nDone! {len(files)} files written.")


def dry_run_only(args):
    return args.dry_run


if __name__ == "__main__":
    main()
