#!/bin/bash

# Default values for the parameters
POLICY_DEFINITION_FILE="policy-definition.json"  # Path to the JSON file containing the policy definition
ASSIGNMENT_NAME="TEST-ASSIGNMENT"
NSG_NAME="TestNSG"
RESOURCE_GROUP="MyTestResourceGroup"

# Parse command-line arguments (optional parameters)
while getopts "p:d:s:f:" opt; do
  case "$opt" in
    p) POLICY_NAME="$OPTARG" ;;
    f) POLICY_DEFINITION_FILE="$OPTARG" ;;
    m) NON_COMPLIANCE_MESSAGE="$OPTARG" ;;
    *) echo "Usage: $0 [-p policy_name] [-f path_to_policy_definition_file] [-m non_compliance_message]"&& exit 1 ;;
  esac
done

# Step 1: Check if the policy definition file exists
if [ ! -f "$POLICY_DEFINITION_FILE" ]; then
  echo "Error: Policy definition file '$POLICY_DEFINITION_FILE' does not exist."
  exit 1
fi

# Step 2: Parse the JSON policy definition file
echo "Parsing the policy definition JSON file..."
DISPLAY_NAME=$(jq -r '.properties.displayName' "$POLICY_DEFINITION_FILE")
DESCRIPTION=$(jq -r '.properties.description' "$POLICY_DEFINITION_FILE")
MODE=$(jq -r '.properties.mode' "$POLICY_DEFINITION_FILE")
PARAMETERS=$(jq -r '.properties.parameters' "$POLICY_DEFINITION_FILE")
POLICY_RULE=$(jq -r '.properties.policyRule' "$POLICY_DEFINITION_FILE")
NON_COMPLIANCE_MESSAGE=$(jq -r '.properties.nonComplianceMessage' "$POLICY_DEFINITION_FILE")

# Step 3: Create the policy definition using parsed values
echo "Creating the Azure Policy Definition..."
az policy definition create \
  --name "$POLICY_NAME" \
  --display-name "$DISPLAY_NAME" \
  --description "$DESCRIPTION" \
  --mode "$MODE" \
  --rules "$POLICY_RULE" \
  --params "$PARAMETERS"


echo "Policy created successfully."

# Step 4: Assign the policy
echo "Assigning the Azure Policy..."
az policy assignment create \
  --name "$ASSIGNMENT_NAME" \
  --policy "$POLICY_NAME" \

#Step 5: Assign a non-compliance message
echo "Adding the Non Compliance Message"
az policy assignment non-compliance-message create \
    --message "$NON_COMPLIANCE_MESSAGE" \
    --name "$ASSIGNMENT_NAME"

# Step 6: Set up resources for testing
echo "Creating a Network Security Group for testing..."
az network nsg create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$NSG_NAME"
