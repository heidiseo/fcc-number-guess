#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=users -t --no-align -c"

echo "Enter your username:"
read USERNAME

NUMBER=$(( $RANDOM % 1000 + 1 ))

USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")

if [[ -z $USER_ID ]] 
then
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  echo "Welcome, $USERNAME! It looks like this is your first time here."
else 
  GAME_DATA=$($PSQL "SELECT games_played, best_game FROM users WHERE user_id=$USER_ID")
  
  echo $GAME_DATA | while IFS="|" read GAMES BEST
  do
    echo "Welcome back, $USERNAME! You have played $GAMES games, and your best game took $BEST guesses."
  done
fi

ATTEMPTS=0

GUESS_NUMBER() {
  ATTEMPTS=$(( $ATTEMPTS + 1 ))
  read GUESS

  if ! [[ $GUESS =~ ^[0-9]+$ ]]
    then
      echo That is not an integer, guess again:
      GUESS_NUMBER
    fi

    # handle correct guess
    if [[ $GUESS == $NUMBER ]]
    then
      USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

      echo $USER_DATA | while IFS="|" read ID GAMES BEST
      do
        # increment games played
        UPDATED_GAMES=$(( $GAMES + 1 ))
        INSERT_GAMES_RESULT=$($PSQL "UPDATE users SET games_played=$UPDATED_GAMES WHERE user_id=$ID")
        # decide if needing to update best game played
        if [[ $BEST == 0 ]]
        then
          INSERT_BEST_RESULT=$($PSQL "UPDATE users SET best_game=$ATTEMPTS WHERE user_id=$ID")
        elif [[ $BEST > $ATTEMPTS ]]
        then
          INSERT_BEST_RESULT=$($PSQL "UPDATE users SET best_game=$ATTEMPTS WHERE user_id=$ID")
        fi    
      done

      echo -e "You guessed it in $ATTEMPTS tries. The secret number was $NUMBER. Nice job!"
    fi

    if [[ $GUESS > $NUMBER ]]
    then
      echo -e "It's lower than that, guess again:"
      GUESS_NUMBER
    fi

    if [[ $GUESS < $NUMBER ]]
    then
      echo -e "It's higher than that, guess again:"
      GUESS_NUMBER
    fi
}

echo Guess the secret number between 1 and 1000:
GUESS_NUMBER
