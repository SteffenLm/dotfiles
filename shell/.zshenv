DIRECTORY=$HOME/.zshenv.d

if [ -d "$DIRECTORY" ]; then
  for file in $DIRECTORY/**/*(-.); source $file
fi

