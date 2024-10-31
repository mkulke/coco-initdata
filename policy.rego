package agent_policy

import future.keywords.in
import future.keywords.if
import future.keywords.every

default AddARPNeighborsRequest := true
default AddSwapRequest := true
default CloseStdinRequest := true
default CopyFileRequest := true
default CreateSandboxRequest := true
default DestroySandboxRequest := true
default GetMetricsRequest := true
default GetOOMEventRequest := true
default GuestDetailsRequest := true
default ListInterfacesRequest := true
default ListRoutesRequest := true
default MemHotplugByProbeRequest := true
default OnlineCPUMemRequest := true
default PauseContainerRequest := true
default PullImageRequest := true
default ReadStreamRequest := true
default RemoveContainerRequest := true
default RemoveStaleVirtiofsShareMountsRequest := true
default ReseedRandomDevRequest := true
default ResumeContainerRequest := true
default SetGuestDateTimeRequest := true
default SetPolicyRequest := true
default SignalProcessRequest := true
default StartContainerRequest := true
default StartTracingRequest := true
default StatsContainerRequest := true
default StopTracingRequest := true
default TtyWinResizeRequest := true
default UpdateContainerRequest := true
default UpdateEphemeralMountsRequest := true
default UpdateInterfaceRequest := true
default UpdateRoutesRequest := true
default WaitProcessRequest := true
default WriteStreamRequest := true

default CreateContainerRequest := false
default ExecProcessRequest := false

CreateContainerRequest if {
        every storage in input.storages {
        some allowed_image in policy_data.allowed_images
        storage.source == allowed_image
    }
}

ExecProcessRequest if {
    input_command = concat(" ", input.process.Args)
        some allowed_command in policy_data.allowed_commands
        input_command == allowed_command
}

policy_data := {
        "allowed_commands": [
                "whoami",
                "false",
                "curl -s http://127.0.0.1:8006/aa/token?token_type=kbs",
        ],
        "allowed_images": [
                "pause",
                "docker.io/library/nginx@sha256:e56797eab4a5300158cc015296229e13a390f82bfc88803f45b08912fd5e3348",
        ],
}
