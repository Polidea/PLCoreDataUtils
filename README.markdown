---

__This repository is no longer maintained. Issue reports and pull requests will not be attended.__

---

# PLCoreDataUtils

## Installation

* Add the files to your project (each class can be used separately)

## Usage

### NSManagedObjectContext+PLCoreDataUtils category

Methods for common tasks on NSManagedObjectContext:

* different types of fetch (single/multiple objects, sorting, etc)
* fetch or insert if not present
* entity cloning

### PLCoreDataStack

Given a main context, setups a small main/background context stack.

* category for propagated saves 

### PLDataSetMerger

Tool for tracking entities that should be removed after parsing a list of objects in network request response. Instead of removing all entities of a type, you:

* add them to the set before parsing
* 'mark' them if they are mentioned in the list
* after parsing order the set to remove the unmentioned entities

---

Copyright (c) 2012 Polidea. This software is licensed under the BSD License.
