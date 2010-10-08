#!/usr/bin/env coffee
#
# CoffeeApp - coffee-script wrapper for CouchApp
# Copyright 2010 Andrzej Sliwa (andrzej.sliwa@i-tool.eu)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

exist = require('path').existsSync
joinPath = require('path').join
extName = require('path').extname
mkDir = require('fs').mkdirSync
readDir = require('fs').readdirSync
writeFile = require('fs').writeFileSync
readFile = require('fs').readFileSync
getStats = require('fs').statSync
coffeeCompile = require('coffee-script').compile
exec  = require('child_process').exec

#### Helper Methods

# Zero padding for format '0x'
padTwo = (number) ->
  result = if number < 10 then '0' else ''
  "#{result}#{number}"

# Timestamp string based on current date
getTimestamp = ->
  date = new Date
  date.getFullYear() + padTwo(date.getMonth() + 1) +
  padTwo(date.getDate()) + padTwo(date.getHours() + 1) +
  padTwo(date.getMinutes() + 1) + padTwo(date.getSeconds() + 1)

# Display outputs if presents
printOutput = (error, stdout, stderr) ->
  console.log stdout if stdout.length > 0
  console.log stderr if stderr.length > 0
  if error != null
    console.log "exec error: #{error}"


#### Main Methods

# Process directory recursivly, normal files
# are copied, directories are recreated and .coffee
# files are "compiled" to javascript
processRecursive = (currentDir, destination) ->
  fileList = readDir currentDir
  for fileName in fileList
    filePath = joinPath currentDir, fileName
    destFilePath = joinPath destination, filePath
    if getStats(filePath).isDirectory()
      unless fileName[0] == '.'
        mkDir destFilePath, 0700
        processRecursive filePath, destination
    else
      # if it's coffee-script file and isn't in _attachments (to using it on client side.)
      if extName(filePath) == '.coffee' and filePath.indexOf('_attachments') == -1
        console.log " * processing #{filePath}..."
        writeFile destFilePath.replace(/\.coffee$/, '.js'),
          coffeeCompile(readFile(filePath, encoding = 'utf8'), noWrap: yes).replace(/^\(/,'').replace(/\);$/, ''), encoding = 'utf8'
      # if it's other files
      else
        exec "cp #{filePath} #{destFilePath}", printOutput


#### Grinding of coffee

# Starts wrapping push command of couchapps
#
# each deploy is moved to .releases/[timestamp] directory
# with processing coffee-script files and then pushed from
# deploy directory.
grindCoffee = ->
  releasesDir = '.releases'
  unless exist releasesDir
    console.log "initialize #{releasesDir} directory"
    mkDir releasesDir, 0700
  releasePath = joinPath releasesDir, getTimestamp()
  console.log "preparing #{releasePath} release..."
  mkDir releasePath, 0700
  processRecursive '.', releasePath
  process.chdir releasePath
  console.log "done."
  exec 'couchapp push', printOutput
  process.cwd()

#### Well, let's dance baby

# Shows greatings ...
console.log 'CoffeeApp (v0.0.5) - simple coffee-script wrapper for CouchApp (http://couchapp.org)'
console.log 'http://github.com/andrzejsliwa/coffeeapp\n'

# only push option is wrapped
if 'push' in process.argv
  console.log "Wrapping 'push' of couchapp"
  # lets do it
  grindCoffee()
else
  # convert options back to string
  options = process.argv.join(' ')
  console.log "Calling couchapp"
  # execute couchapp command
  exec "couchapp #{options}", printOutput
