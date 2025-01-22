#!/bin/bash

# Default values for the parameters
POLICY_DEFINITION_FILE="policy-definition.json"
ASSIGNMENT_NAME="TEST-ASSIGNMENT"
NSG_NAME="TestNSG"
RESOURCE_GROUP="MyTestResourceGroup"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Function for error handling
handle_error() {
    local exit_code=$1
    local error_message=$2
    if [ $exit_code -ne 0 ]; then
        echo "Error: $error_message"
        exit $exit_code
    fi
}

# Parse command-line arguments
while getopts "p:a:f:" opt; do
    case "$opt" in
        p) POLICY_NAME="$OPTARG" ;;
        a) ASSIGNMENT_NAME="$OPTARG" ;;
        f) POLICY_DEFINITION_FILE="$OPTARG" ;;
        *) echo "Usage: $0 [-p policy_name] [-a assignment_name] [-f policy_definition_file]" && exit 1 ;;
    esac
done

# Validate required parameters
if [ -z "$POLICY_NAME" ]; then
    echo "Error: Policy name (-p) is required"
    exit 1
fi

# Check if user is logged in to Azure
az account show > /dev/null 2>&1
handle_error $? "Not logged in to Azure. Please run 'az login' first."

# Validate policy definition file
if [ ! -f "$POLICY_DEFINITION_FILE" ]; then
    echo "Error: Policy definition file '$POLICY_DEFINITION_FILE' does not exist."
    exit 1
fi

# Validate JSON format
jq empty "$POLICY_DEFINITION_FILE" 2>/dev/null
handle_error $? "Invalid JSON format in policy definition file"

# Parse the JSON policy definition file with error checking
echo "Parsing the policy definition JSON file..."
DISPLAY_NAME=$(jq -r '.properties.displayName // empty' "$POLICY_DEFINITION_FILE")
DESCRIPTION=$(jq -r '.properties.description // empty' "$POLICY_DEFINITION_FILE")
MODE=$(jq -r '.properties.mode // empty' "$POLICY_DEFINITION_FILE")
PARAMETERS=$(jq -r '.properties.parameters // empty' "$POLICY_DEFINITION_FILE")
POLICY_RULE=$(jq -r '.properties.policyRule // empty' "$POLICY_DEFINITION_FILE")
MESSAGE=$(jq -r '.properties.nonComplianceMessage // empty' "$POLICY_DEFINITION_FILE")

# Validate required fields
for field in "$DISPLAY_NAME" "$MODE" "$POLICY_RULE"; do
    if [ -z "$field" ]; then
        echo "Error: Missing required fields in policy definition file"
        exit 1
    fi
done

# Create the policy definition with error handling
echo "Creating the Azure Policy Definition..."
az policy definition create \
    --name "$POLICY_NAME" \
    --display-name "$DISPLAY_NAME" \
    --description "$DESCRIPTION" \
    --mode "$MODE" \
    --rules "$POLICY_RULE" \
    --params "$PARAMETERS"
handle_error $? "Failed to create policy definition"

echo "Policy definition created successfully."

az policy assignment create \
    --name "$ASSIGNMENT_NAME" \
    --policy "$POLICY_NAME"
handle_error $? "Failed to create policy assignment"

echo "Policy assigned successfully."

# Set non-compliance message if provided
if [ -n "$MESSAGE" ]; then
    echo "Creating Non-Compliance Message..."
    az policy assignment non-compliance-message create \
        --message "$MESSAGE" \
        --name "$ASSIGNMENT_NAME"
    handle_error $? "Failed to set non-compliance message"
    echo "Non-compliance message set successfully."
fi

# Verify policy assignment
echo "Verifying policy assignment..."
az policy assignment show \
    --name "$ASSIGNMENT_NAME" \
    --query "id" -o tsv
handle_error $? "Failed to verify policy assignment"

echo "Policy deployment completed successfully."
