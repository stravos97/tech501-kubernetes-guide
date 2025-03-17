#!/bin/bash
# Script to increase EC2 instance storage space

# Set variables
INSTANCE_IP="3.254.153.213"

# Function to handle errors
function error_exit {
    echo "ERROR: $1" >&2
    exit 1
}

echo "====== AWS EC2 Volume Resize Script ======"
echo "Target Instance IP: $INSTANCE_IP"

# Step 1: Get instance ID
echo "Finding instance ID for IP $INSTANCE_IP..."
# List all instances and filter for the one with our IP
INSTANCE_ID=$(aws ec2 describe-instances --query "Reservations[*].Instances[*].[InstanceId,PublicIpAddress]" --output text | grep $INSTANCE_IP | awk '{print $1}')

if [ -z "$INSTANCE_ID" ]; then
    error_exit "Could not find instance with IP $INSTANCE_IP"
fi
echo "Found instance: $INSTANCE_ID"

# Step 2: Get volume ID
echo "Finding root volume ID for instance $INSTANCE_ID..."
VOLUME_ID=$(aws ec2 describe-instances --instance-ids "$INSTANCE_ID" --query "Reservations[0].Instances[0].BlockDeviceMappings[0].Ebs.VolumeId" --output text)

if [ -z "$VOLUME_ID" ] || [ "$VOLUME_ID" == "None" ]; then
    error_exit "Could not find volume for instance $INSTANCE_ID"
fi
echo "Found volume: $VOLUME_ID"

# Step 3: Get current volume size
CURRENT_SIZE=$(aws ec2 describe-volumes --volume-ids "$VOLUME_ID" --query "Volumes[0].Size" --output text)
echo "Current volume size: $CURRENT_SIZE GB"

# Step 4: Modify volume to new size
NEW_SIZE=15
if [ "$CURRENT_SIZE" -ge "$NEW_SIZE" ]; then
    echo "Current size ($CURRENT_SIZE GB) is already greater than or equal to target size ($NEW_SIZE GB). No resize needed."
    exit 0
fi

echo "Resizing volume $VOLUME_ID to $NEW_SIZE GB..."
aws ec2 modify-volume --volume-id "$VOLUME_ID" --size "$NEW_SIZE" || error_exit "Failed to resize volume"

# Step 5: Wait for the resize to complete
echo "Waiting for volume modification to complete..."
while true; do
    STATE=$(aws ec2 describe-volumes-modifications --volume-ids "$VOLUME_ID" --query "VolumesModifications[0].ModificationState" --output text)
    
    if [ "$STATE" == "completed" ]; then
        echo "Volume modification completed successfully!"
        break
    elif [ "$STATE" == "failed" ]; then
        error_exit "Volume modification failed"
    else
        echo "Current state: $STATE. Waiting..."
        sleep 10
    fi
done

# Step 6: Extend the file system on the instance
echo "Extending the file system on the instance..."
ssh ubuntu@$INSTANCE_IP "sudo growpart /dev/xvda 1 && sudo resize2fs /dev/xvda1" || {
    echo "NOTE: Could not automatically extend the file system."
    echo "You may need to manually run the following commands on the instance:"
    echo "  sudo growpart /dev/xvda 1"
    echo "  sudo resize2fs /dev/xvda1"
    echo "The exact device name might vary. Use 'lsblk' to identify the correct device."
}

# Step 7: Verify the new space
echo "Verifying the new space..."
ssh ubuntu@$INSTANCE_IP "df -h /" || error_exit "Could not verify new space"

echo "====== Volume resize completed successfully ======"
echo "The instance now has a $NEW_SIZE GB volume."
