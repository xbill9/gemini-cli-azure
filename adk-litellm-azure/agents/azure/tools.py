import subprocess

def list_azure_resource_groups() -> str:
    """
    Lists all Azure Resource Groups in the current subscription.
    Returns a table-formatted string of resource groups.
    """
    try:
        result = subprocess.run(
            ["az", "group", "list", "-o", "table"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except Exception as e:
        return f"Error listing resource groups: {str(e)}"

def list_azure_storage_accounts() -> str:
    """
    Lists all Azure Storage Accounts in the current subscription.
    """
    try:
        result = subprocess.run(
            ["az", "storage", "account", "list", "-o", "table"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except Exception as e:
        return f"Error listing storage accounts: {str(e)}"

def list_azure_vms() -> str:
    """
    Lists all Azure Virtual Machines in the current subscription.
    """
    try:
        result = subprocess.run(
            ["az", "vm", "list", "-d", "-o", "table"],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout
    except Exception as e:
        return f"Error listing VMs: {str(e)}"
