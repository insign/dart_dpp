class WrongGitBranchException implements Exception {
  final String? expectedBranch;

  WrongGitBranchException(this.expectedBranch);

  @override
  String toString() {
    final branchStr = expectedBranch ?? 'main or master';
    return 'WrongGitBranchException: Not on $branchStr branch. Checkout $branchStr or use --any-branch to allow publishing from current branch.';
  }
}
