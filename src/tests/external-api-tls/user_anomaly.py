import requests

cert_path = "./client-cert-1.pem"
key_path = "./client-key-1.pem"
ca_path = "./ca.pem"

def get_anomalies_users():
    opa_url = "https://127.0.0.1:8181/v1/data/anomalies/users"
    response = requests.get(opa_url, cert=(cert_path, key_path), verify=ca_path)
    if response.status_code == 200:
        return response.json().get("result", [])
    else:
        print("Failed to get anomalies users:", response.text)
        return None

def update_anomalies_users(users):
    opa_url = "https://127.0.0.1:8181/v1/data/anomalies/users"
    response = requests.put(opa_url, json=users, cert=(cert_path, key_path), verify=ca_path)
    return response.status_code == 204

def add_user_to_anomalies(user):
    users = get_anomalies_users()
    if users is not None:
        if user not in users:
            users.append(user)
            if update_anomalies_users(users):
                print("User added successfully.")
            else:
                print("Failed to add user.")
        else:
            print("User already exists in the list.")
    else:
        print("Failed to retrieve the existing users.")

def delete_user_from_anomalies(user):
    users = get_anomalies_users()
    if users is not None:
        if user in users:
            users.remove(user)
            if update_anomalies_users(users):
                print("User removed successfully.")
            else:
                print("Failed to remove user.")
        else:
            print("User not found in the list.")
    else:
        print("Failed to retrieve the existing users.")

def main():
    action = input("Do you want to add or delete a user to the forbidden list? (add/delete): ").strip().lower()
    user = input("Enter the user ID: ").strip()

    if action == "add":
        add_user_to_anomalies(user)
    elif action == "delete":
        delete_user_from_anomalies(user)
    else:
        print("Invalid action. Please choose 'add' or 'delete'.")

if __name__ == "__main__":
    main()
