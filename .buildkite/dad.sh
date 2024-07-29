#!/bin/bash

# Function to generate a random integer within a range
random_int() {
  local min=$1
  local max=$2
  echo $((RANDOM % (max - min + 1) + min))
}

# Function to determine if we should fail
should_fail() {
  local chance=$1
  if [ $((RANDOM % 100)) -lt $chance ]; then
    return 0 # fail
  else
    return 1 # succeed
  fi
}

# Read environment variables
DURATION=${DURATION:-60}
DURATION_VARIABILITY=${DURATION_VARIABILITY:-30}
FAILURE_CHANCE=${FAILURE_CHANCE:-10}

# Calculate random variation
VARIATION=$((RANDOM % (DURATION_VARIABILITY * 2 + 1) - DURATION_VARIABILITY))
RANDOM_DURATION=$((DURATION + VARIATION))

# Ensure duration is not less than 1
if [ $RANDOM_DURATION -lt 1 ]; then
  RANDOM_DURATION=1
fi

# Determine if it will fail
if should_fail $FAILURE_CHANCE; then
  WILL_FAIL=true
else
  WILL_FAIL=false
fi

# Log provided variables and calculated values
echo "DURATION: $DURATION"
echo "DURATION_VARIABILITY: $DURATION_VARIABILITY"
echo "FAILURE_CHANCE: $FAILURE_CHANCE"
echo "Calculated RANDOM_DURATION: $RANDOM_DURATION"
echo "Will the script fail? $WILL_FAIL"

# Start time
START_TIME=$(date +%s)
END_TIME=$((START_TIME + RANDOM_DURATION))

echo "Generating log output for $RANDOM_DURATION seconds..."

# Read jokes into an array
mapfile -t JOKES < .buildkite/jokes
JOKES_COUNT=${#JOKES[@]}

while [ $(date +%s) -lt $END_TIME ]; do
  sleep 2
  RANDOM_JOKE_INDEX=$(random_int 0 $((JOKES_COUNT - 1)))
  echo "${JOKES[$RANDOM_JOKE_INDEX]}"
done

# Output final result based on WILL_FAIL
if [ "$WILL_FAIL" = true ]; then
  echo "Script finished with FAILURE."
  exit 1
else
  echo "Script finished with SUCCESS."
  exit 0
fi
