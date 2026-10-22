#!/bin/bash
# 交互式询问是否创建普通用户

echo "=========================================="
echo " Create a regular user?"
echo "=========================================="

ANSWER=""
read -p "Create user? [y/N]: " ANSWER
echo

case "$ANSWER" in
    [Yy]*)
        while :; do
            read -p "Username: " USERNAME
            [ -n "$USERNAME" ] && break
            echo "Username cannot be empty, please try again."
        done

        if id "$USERNAME" >/dev/null 2>&1; then
            echo "User $USERNAME already exists, skipping creation."
            exit 0
        fi

        while :; do
            read -s -p "Password: " P1
            echo
            read -s -p "Confirm Password: " P2
            echo

            case "$P1" in
                *:*) echo "Password cannot contain a colon, please try again."; continue ;;
            esac

            if [ -n "$P1" ] && [ "$P1" = "$P2" ]; then
                break
            fi
            echo "Passwords do not match or are empty, please try again."
        done

        # 顺手把 sudo 也装上，并加入 sudo 组
        apt-get update -qq >/dev/null 2>&1 || true
        DEBIAN_FRONTEND=noninteractive apt-get install -y -qq sudo >/dev/null 2>&1 || true
        
        if useradd -m -s /bin/bash "$USERNAME"; then
            printf '%s:%s\n' "$USERNAME" "$P1" | chpasswd
            usermod -aG sudo "$USERNAME" 2>/dev/null || true
            echo "User $USERNAME created successfully (with sudo)."
        else
            echo "Failed to create user, please check logs."
        fi
        ;;
    *)
        echo "Skipping user creation."
        ;;
esac