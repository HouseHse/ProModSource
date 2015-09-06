#!/bin/bash

cp -R build_clean/ build

echo "Pulling from git repositories..."
cd Github
for dir in $(ls); do
  echo "Pulling $dir:"
  cd $dir
  git pull
  cd ..
done

echo "Collating scripting files..."
for file in $(find . -iname "*.sp"); do
  cp $file ../build
done
for file in $(find . -iname "*.inc"); do
  cp $file ../build/include/
done
for file in $(find . -iname "*.txt"); do
  cp $file ../build/gamedata/
done

echo "Compiling files..."
cd ../build
while true; do
  ./compile.sh > temp.txt
  ERROR_FILE="`cat temp.txt | grep error | cut -d '(' -f 1`"
  echo $ERROR_FILE
  rm temp.txt

  # Moving all sucessfully compiled files to plugins and scripting.
  for file in $(find ./compiled -iname "*.smx"); do
    mv $file ../plugins
    FILENAME="`echo $file | cut -d '/' -f 3 | cut -d '.' -f 1`"
    mv "$FILENAME.sp" ../scripting
  done

  # Handling files with errors.
  if [ ! -z "${ERROR_FILE// /}" ]; then
    echo "Could not compile $ERROR_FILE."
    mv $ERROR_FILE ../failed/
  else
    break
  fi
done
cd ..
rm -rf build