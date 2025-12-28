#!/bin/bash
##############################################################################
# Quick Key Switcher - Manually switch between backup encryption keys
##############################################################################

CONFIG_FILE="openkore-master/control/config.txt"

# All backup keys
declare -a KEYS=(
    "d150f7d25803840452acdc9423ca66c1"  # Key 1 (current)
    "50f7d25803840452acdc9423ca66c1a4"  # Key 2
    "6a878404d2823ba4c16c2400da894c25"  # Key 3
    "c6044c3e0fbe140cc0cae533c366f7d9"  # Key 4
    "044c3e0fbe140cc0cae533c366f7d9e8"  # Key 5
)

echo ""
echo "======================================================================"
echo "Gepard Shield Encryption Key Switcher"
echo "======================================================================"
echo ""
echo "Available keys (ranked by entropy):"
echo ""

for i in "${!KEYS[@]}"; do
    num=$((i + 1))
    echo "  [$num] ${KEYS[$i]}"
done

echo ""
echo "Current key in config:"
grep "^gepard_key" "$CONFIG_FILE" || echo "  (not found)"
echo ""

read -p "Enter key number to use (1-${#KEYS[@]}), or 'q' to quit: " choice

if [[ "$choice" == "q" ]] || [[ "$choice" == "Q" ]]; then
    echo "Cancelled."
    exit 0
fi

if [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#KEYS[@]}" ]]; then
    idx=$((choice - 1))
    new_key="${KEYS[$idx]}"
    
    echo ""
    echo "Setting key #$choice: $new_key"
    
    # Use sed to replace the key line
    if grep -q "^gepard_key" "$CONFIG_FILE"; then
        sed -i "s/^gepard_key .*/gepard_key $new_key/" "$CONFIG_FILE"
        echo "✓ Config updated!"
    else
        echo "ERROR: gepard_key line not found in config"
        exit 1
    fi
    
    echo ""
    echo "Now run: cd openkore-master && perl openkore.pl"
    echo ""
else
    echo "Invalid choice."
    exit 1
fi
