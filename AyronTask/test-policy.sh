#!/bin/bash

# Default values for testing parameters
RESOURCE_GROUP="MyTestResourceGroup"
NSG_NAME="TestNSG"
ASSIGNMENT_NAME="Restrict-HTTP-Traffic-Assignment"

# Parse command-line arguments for tests
while getopts "p:" opt; do
  case "$opt" in
    p) POLICY_NAME="$OPTARG" ;;
    *) echo "Usage: $0 [-p policy_name]" && exit 1 ;;
  esac
done

# Function to test the "Restrict Inbound UDP Traffic" policy
test_restrict_udp_traffic() {
  echo "Testing 'Restrict Inbound UDP Traffic' policy..."

  # Test a rule that allows inbound UDP traffic (should fail)
  az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "TestInboundUDP" \
    --priority 1000 \
    --direction Inbound \
    --access Allow \
    --protocol Udp \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "5000" \
    && echo "Test failed: Policy did not block UDP traffic." \
    || echo "Test passed: Policy successfully blocked UDP traffic."

  # Test a non-UDP rule (should pass)
  az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "TestNonUDP" \
    --priority 1001 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "80" \
    && echo "Test passed: Non-UDP traffic allowed." \
    || echo "Test failed: Policy incorrectly blocked non-UDP traffic."
}

# Function to test the "Restrict Inbound Traffic from Source IP 1.2.3.4" policy
test_restrict_ip_traffic() {
  echo "Testing 'Restrict Inbound Traffic from Source IP 1.2.3.4' policy..."

  # Test a rule that allows inbound traffic from IP 1.2.3.4 (should fail)
  az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "TestInboundFrom1.2.3.4" \
    --priority 1002 \
    --direction Inbound \
    --access Allow \
    --source-address-prefixes "1.2.3.4" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "80" \
    && echo "Test failed: Policy did not block traffic from 1.2.3.4." \
    || echo "Test passed: Policy successfully blocked traffic from 1.2.3.4."

  # Test a non-restricted IP (should pass)
  az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "TestInboundFromOtherIP" \
    --priority 1003 \
    --direction Inbound \
    --access Allow \
    --source-address-prefixes "5.6.7.8" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "80" \
    && echo "Test passed: Traffic allowed from other IP." \
    || echo "Test failed: Policy incorrectly blocked traffic from other IP."
}

# Function to test the "Restrict HTTP Traffic" policy
test_restrict_http_traffic() {
  echo "Testing 'Restrict HTTP Traffic' policy..."

  # Test a rule allowing HTTP (port 80) (should fail)
  az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "TestInboundHTTP" \
    --priority 1004 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "80" \
    && echo "Test failed: Policy did not block HTTP traffic on port 80." \
    || echo "Test passed: Policy successfully blocked HTTP traffic on port 80."

  # Test a rule allowing HTTPS (port 443) (should fail)
  az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "TestInboundHTTPS" \
    --priority 1005 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "443" \
    && echo "Test failed: Policy did not block HTTPS traffic on port 443." \
    || echo "Test passed: Policy successfully blocked HTTPS traffic on port 443."

  # Test a rule for other ports (should pass)
  az network nsg rule create \
    --resource-group "$RESOURCE_GROUP" \
    --nsg-name "$NSG_NAME" \
    --name "TestInboundNonHTTP" \
    --priority 1006 \
    --direction Inbound \
    --access Allow \
    --protocol Tcp \
    --source-address-prefixes "*" \
    --source-port-ranges "*" \
    --destination-address-prefixes "*" \
    --destination-port-ranges "1234" \
    && echo "Test passed: Non-HTTP/HTTPS traffic allowed." \
    || echo "Test failed: Policy incorrectly blocked non-HTTP/HTTPS traffic."
}
