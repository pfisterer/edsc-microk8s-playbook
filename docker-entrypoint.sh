#!/bin/bash -x

# ---------------------------------------------------------
# Generate ssh key if none exists
# ---------------------------------------------------------

SSH_PRIV_FILE=/root/.ssh/id_rsa
SSH_PUB_FILE=/root/.ssh/id_rsa.pub

# Check if ssh key should be used to from env variables
if [[ ! -z "$USE_SSH_PRIV_KEY" && ! -z "$USE_SSH_PUB_KEY" ]]; then
	echo "Using ssh pub/priv key from env variables"

	DIR=`dirname $SSH_PRIV_FILE`
	test -d "$DIR" || mkdir -p "$DIR"
	
	echo "$USE_SSH_PRIV_KEY" > "$SSH_PRIV_FILE"
	echo "$USE_SSH_PUB_KEY" > "$SSH_PUB_FILE"

	chmod 600 -R "$DIR"
	chmod 700 "$DIR"
fi

# If no key exists, create new one
if [[ ! -f "$SSH_PRIV_FILE" || ! -f "$SSH_PUB_FILE"  ]]; then
	echo "No existing ssh key $SSH_PRIV_FILE ; generating a new ssh key"
	ssh-keygen -b 2048 -t rsa -q -N "" -f $SSH_PRIV_FILE
fi

# ---------------------------------------------------------
# Run Ansible playbook
# ---------------------------------------------------------

ANSIBLE_LOG_FILE="/data/ansible.log"
JSON_STATUS_FILE="/data/result.json"

echo "Running $@"
"$@" 2>&1 | tee "$ANSIBLE_LOG_FILE" 2>&1

ANSIBLE_EXIT_CODE=$?
echo "Ansible exit code is $ANSIBLE_EXIT_CODE"

# ---------------------------------------------------------
# Report results to $STATUS_REPORT_POST_URL
# ---------------------------------------------------------

echo "Status report URL is $STATUS_REPORT_POST_URL"
if [[ ! -z "$STATUS_REPORT_POST_URL" ]]; then

	# ---------------------------------------------------------
	# Set parameters for jq
	# ---------------------------------------------------------

	KUBE_CONFIG="--arg kc '' "
	if [[ -f "$GENERATED_KUBECONFIG" ]]; then
		KUBE_CONFIG="--rawfile kc $GENERATED_KUBECONFIG"
	fi

	SERVER_LIST="--arg sl '' "
	if [[ -f "$GENERATED_SERVER_LIST" ]]; then
		SERVER_LIST="--rawfile sl $GENERATED_SERVER_LIST"
	fi

	ANSIBLE_LOG="--arg log '' "
	if [[ -f "$ANSIBLE_LOG_FILE" ]]; then
		ANSIBLE_LOG="--rawfile log $ANSIBLE_LOG_FILE"
	fi

	SSH_DATA="--arg ssh_priv '' --arg ssh_pub '' "
	if [[ -f "$SSH_PRIV_FILE" && -f "$SSH_PUB_FILE" ]]; then
		SSH_DATA="--rawfile ssh_priv $SSH_PRIV_FILE --rawfile ssh_pub $SSH_PUB_FILE"
	fi

	# ---------------------------------------------------------
	# Generate JSON
	# ---------------------------------------------------------

	jq -n --arg ec "$ANSIBLE_EXIT_CODE" \
		$KUBE_CONFIG $SERVER_LIST $ANSIBLE_LOG $SSH_DATA \
		'{exit_code: $ec, kubeconfig: $kc, serverlist: $sl, log_output: $log, ssh_priv: $ssh_priv, ssh_pub: $ssh_pub}' \
		> "$JSON_STATUS_FILE"

	echo "Contents of $JSON_STATUS_FILE:"
	cat "$JSON_STATUS_FILE"

	# ---------------------------------------------------------
	# Upload JSON to $STATUS_REPORT_POST_URL
	# ---------------------------------------------------------

	echo "Uploading status to $STATUS_REPORT_POST_URL"
 	curl --silent --show-error -X POST -H "Content-Type: application/json" --data "@$JSON_STATUS_FILE" "$STATUS_REPORT_POST_URL"

fi

echo "Done."
