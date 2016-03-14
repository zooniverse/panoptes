
Describe your change here.

# Review checklist

* First, the most important one: is this PR small enough that you can actually review it? Feel free to just reject a branch if the changes are hard to review due to the length of the diff.
* If there are any migrations, will they the previous version of the app work correctly after they've been run (e.g. the don't remove columns still known about by ActiveRecord).
* If anything changed with regards to the public API, are those changes also documented in the `apiary.apib` file?
* Are all the changes covered by tests? Think about any possible edge cases that might be left untested.
