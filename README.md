# Crows & Vultures

A digital implementation of the traditional Crows & Vultures (Kaooa)
strategy game built using Godot 4.x and GDScript.

## Requirements

- Godot 4.x
- Git
- GitHub account

## First-Time Setup

1. Clone the repository:

   git clone https://github.com/NShenbagakrithika/crows-and-vultures

2. Open Godot.

3. Click "Import".

4. Navigate to the cloned project folder.

5. Select `project.godot`.

6. Click "Import & Edit".

7. Run the project using the Play Project button or F6/F5 as appropriate.

## Development Workflow

Do not develop directly on `main`.

Before starting work:

git checkout main
git pull origin main

Create a branch for your task:

git checkout -b feature/<feature-name>

Example:

git checkout -b feature/restart-system

Make your changes and test them in Godot.

Then:

git status
git add .
git commit -m "Add restart functionality"
git push -u origin feature/restart-system

Create a Pull Request on GitHub from your branch into `main`.

Do not merge until the feature has been tested.

## Important

Never force-push to `main`.

Always pull the latest `main` before starting a new feature.

Avoid having two developers edit the same `.tscn` scene simultaneously
because Godot scene files can create difficult merge conflicts.
