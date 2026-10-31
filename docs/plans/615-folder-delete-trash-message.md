# #615 Folder delete tells the truth about Recently deleted

**Reference check:** GoodNotes (deleting a folder moves its documents to Recently Deleted),
Flexcil (trash keeps deleted folder contents restorable) and StarNote (deleted items go to
trash) all warn that contents go to the trash and can be restored → same: one confirm text
that says the notes move to Recently deleted, and a success toast with the count.

## Steps
1. `FolderRepository.deleteFolder` returns `Either<Failure, int>` = number of notes moved to
   the trash. The impl walks all descendants (`FolderTree.descendantIds`), not only direct
   children, so the "subfolders included" wording is true at any depth.
   Test: nested root/sub/subsub folder delete trashes all three docs and returns 3.
2. `FoldersController.deleteFolder` returns `Future<int?>` (null on failure).
3. Strings: `libraryDeleteFolderConfirm(name, count)` (plural, =0 plain question) replaces
   `libraryDeleteFolderNonEmptyMessage`/`libraryDeleteFolderMessage`; new
   `libraryFolderDeletedNotesTrashed(count)` toast. EN + TR.
4. Library folder menu and Manage Folders both use `libraryDeleteFolderConfirm` with
   `folder.documentCount` (already recursive) and the count toast when > 0.
5. Widget tests: library menu dialog text; Manage Folders dialog text; count toast.
