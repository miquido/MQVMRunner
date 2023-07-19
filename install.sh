RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f MQVMRunner ]; then
    echo "${RED}MQVMRunner binary not found, did you forget to run: ${BLUE}make build${RED}?"
    exit 1
fi
# $1=prompt, $2=default value, $3=hide input
readInputWithDefault() {
  local result
  local defaultValueText=$2
  if [ -z "$defaultValueText" ]; then
    defaultValueText=$(echo "\033[3mempty\033[23m")
  fi
  PROMPT=$(echo "${NC}$1 [default: ${YELLOW}${defaultValueText}${NC}]: ")
  
  if [ "$3" = true ]; then
    read -r -s -p "$PROMPT" result
  else
    read -r -p "$PROMPT" result
  fi
  if [ -z "$result" ]; then
    result="$2"
  fi
  echo "$result"
}
# $1=prompt, $2=hide input
readInput() {
  local result
  PROMPT=$(echo "${NC}$1: ")
  while [ -z "$result" ]; do
      if [ "$2" = true ]; then
        read -r -s -p "$PROMPT" result;
      else
        read -r -p "$PROMPT" result;
      fi
  done
  echo "$result"
}

RUNNER_PATH=$(readInputWithDefault "Path to store custom runner executables" "$HOME/custom-gitlab-runner")
RUNNER_PATH="${RUNNER_PATH/#\~/$HOME}"
VM_USER=$(readInput "VM user")
authTypes=("password" "key")
AUTH=""
echo "${NC}Select authentication type - password or private key:${GREEN}"
while [ -z "$AUTH" ]; do
  select type in "${authTypes[@]}"; do
      case $type in
          "password")
              password=$(readInput "VM password" true)
              printf "\n" #secure entry leaves cursor on the same line
              AUTH="--password-authentication $password"
              break
              ;;
          "key")
              key=$(readInputWithDefault "Path to private key to access VM" "$HOME/.ssh/id_rsa")
              key="${key/#\~/$HOME}"
              pass=$(readInputWithDefault "Password to decipher private key, leave empty for no password."  ""  true)
              printf "\n" #secure entry leaves cursor on the same line
              if [ -n "$pass" ]; then
                pass="--private-key-password $pass"
              fi
              AUTH="--private-key $key $pass"
              break
              ;;
          *)
              break
              ;;
      esac
  done
done

GITLAB_URL=$(readInputWithDefault "GitLab instance URL", "https://gitlab.com/")
GITLAB_TOKEN=$(readInput "GitLab runner token")
RUNNER_NAME=$(readInputWithDefault "Runner name" "VMRunner")
cacheAnswer=("yes" "no")
CACHE_PATH=""
CACHE_ARGUMENT=""
CACHE_MOUNT=""
echo "${NC}Do you want to setup cache?${GREEN}"
while [ -z "$CACHE_PATH" ]; do
  select type in "${cacheAnswer[@]}"; do
      case $type in
          "yes")
              CACHE_PATH=$(readInputWithDefault "Path to store GitLab cache" "$HOME/gitlab_cache")
              CACHE_PATH="${CACHE_PATH/#\~/$HOME}"
              CACHE_ARGUMENT=("--cache-dir" "/Volumes/My Shared Files/gitlab_cache")
              CACHE_MOUNT="--mount \"$CACHE_PATH=gitlab_cache\""
              break
              ;;
          "no")
              CACHE_PATH=" "
              break
              ;;
          *)
              break
              ;;
      esac
  done
done

substitutePlaceholders() {
  sed -i '' "s#RUNNER_PATH#$RUNNER_PATH#g" "$1"
  sed -i '' "s#VM_USER#$VM_USER#g" "$1"
  sed -i '' "s#AUTH#$AUTH#g" "$1"
  sed -i '' "s#CACHE_MOUNT#$CACHE_MOUNT#g" "$1"
}

echo "${GREEN}Moving files to $RUNNER_PATH."
mkdir -p "$RUNNER_PATH"
cp MQVMRunner "$RUNNER_PATH/MQVMRunner"
cp Scripts/*.sh "$RUNNER_PATH/"

echo "${GREEN}Substituting placeholders with actual values."
substitutePlaceholders "$RUNNER_PATH/prepare.sh"
substitutePlaceholders "$RUNNER_PATH/run.sh"
substitutePlaceholders "$RUNNER_PATH/cleanup.sh"
chmod -R 755 "$RUNNER_PATH"
echo "${GREEN}Configuring gitlab-runner."
gitlab-runner register --non-interactive \
  --url "$GITLAB_URL" \
  --name "$RUNNER_NAME" \
  --registration-token "$GITLAB_TOKEN" \
  --executor custom \
  --custom-prepare-exec "$RUNNER_PATH/prepare.sh" \
  --custom-run-exec "$RUNNER_PATH/run.sh" \
  --custom-cleanup-exec "$RUNNER_PATH/cleanup.sh" \
  --builds-dir "/Users/$VM_USER/gitlab_builds" \
  "${CACHE_ARGUMENT[@]}"
result=$?

if [ $result -ne 0 ]; then
    echo "${RED}Failed to register runner - see logs above. Exiting."
    exit 1
fi

echo "${GREEN}Installing GitLab runner.${NC}"
gitlab-runner install
result=$?
if [ $result -ne 0 ]; then
    echo "${RED}Failed to install runner - see logs above. Exiting."
    exit 1
fi

echo "${GREEN}Starting GitLab runner.${NC}"
gitlab-runner start
result=$?
if [ $result -ne 0 ]; then
    echo "${RED}Failed to start runner - see logs above. Exiting."
    exit 1
fi

echo "${GREEN}Done."
