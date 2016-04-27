
# darcs-log-utils
Utility methods for parsing `darcs changes` output

## Installation
```
  npm install git-log-utils
  
```
## Usage
```javascript

DarcsLogUtils = require('darcs-log-utils')

DarcsLogUtils.getFileCommitHistory(fileName)
```
Returns an array of javascript objects representing the commits that effected the requested file
with line stats, that looks like this:
```javascript  
[{
  "hash": "84b7bd17809b9dd805af7228787acfa194d0da08",
  "authorName": "matt.whitslar@email.com",
  "authorDate": 1450881433,
  "message": "docs all work again after refactoring to bumble-build",
  "body": "",
  "linesAdded": 2,
  "linesDeleted": 2
}, {
  ...
}]
```

