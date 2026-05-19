from __future__ import annotations

import pytest

from mcp_azure_personal.tools import (
    _normalize_aks_machine_names,
    _require_same_aks_machine_names,
    register_tools,
)


class _Recorder:
    def __init__(self):
        self.tools = {}

    def tool(self):
        def decorator(fn):
            self.tools[fn.__name__] = fn
            return fn

        return decorator


def test_aks_delete_agent_pool_machines_dry_run_builds_delete_machines_request():
    recorder = _Recorder()
    register_tools(recorder)

    result = recorder.tools["aks_delete_agent_pool_machines"](
        subscription="sub-123",
        resource_group="infra",
        cluster="infra-aks",
        agent_pool="user",
        machine_names=["aks-user-34069586-vmss000002"],
        confirm_agent_pool="user",
        confirm_machine_names=["aks-user-34069586-vmss000002"],
    )

    assert result["dry_run"] is True
    assert result["request"]["method"] == "POST"
    assert result["request"]["path"] == (
        "/subscriptions/sub-123/resourceGroups/infra"
        "/providers/Microsoft.ContainerService/managedClusters/infra-aks"
        "/agentPools/user/deleteMachines?api-version=2025-07-01"
    )
    assert result["request"]["body"] == {
        "machineNames": ["aks-user-34069586-vmss000002"],
    }


def test_normalize_aks_machine_names_strips_and_preserves_order():
    assert _normalize_aks_machine_names([
        " aks-user-34069586-vmss000002 ",
        "aks-user-34069586-vmss000003",
    ]) == [
        "aks-user-34069586-vmss000002",
        "aks-user-34069586-vmss000003",
    ]


def test_normalize_aks_machine_names_rejects_duplicates():
    with pytest.raises(ValueError, match="duplicate"):
        _normalize_aks_machine_names([
            "aks-user-34069586-vmss000002",
            "aks-user-34069586-vmss000002",
        ])


def test_confirm_machine_names_allows_different_order():
    _require_same_aks_machine_names(
        ["aks-user-34069586-vmss000002", "aks-user-34069586-vmss000003"],
        ["aks-user-34069586-vmss000003", "aks-user-34069586-vmss000002"],
    )


def test_confirm_machine_names_rejects_mismatch():
    with pytest.raises(ValueError, match="exactly the same"):
        _require_same_aks_machine_names(
            ["aks-user-34069586-vmss000002"],
            ["aks-user-34069586-vmss000001"],
        )
