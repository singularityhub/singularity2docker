# singularity2docker

This is a simple script to convert a Singularity image back to Docker, preserving
environment, labels, and runscript. The usage is as follows:

```bash
./singularity2docker.sh -n newcontainer:tag singularity-container.sif
```

The above says "Create a new container called newcontainer:tag (-n == name) from
the Singularity container singularity-container.sif The other argument you can provide
to skip cleanup of the sandbox (if you intend to build again) is `--no-cleanup`.

## Example

```
$ ./singularity2docker.sh -n newcontainer:tag singularity-container.sif

Input Image: singularity-container.sif

1. Checking for software dependencies, Singularity and Docker...
Found Singularity 2.4.5-master.g0b17e18
Found Docker Docker version 18.03.0-ce, build 0520e24

2.  Preparing sandbox for export...

3.  Exporting metadata...
Adding LABEL "MAINTAINER" vanessasaur
Adding LABEL "WHATAMI" dinosaur
Adding LABEL "org.label-schema.build-date" 2017-10-15T12:52:56+00:00
Adding LABEL "org.label-schema.build-size" 333MB
Adding LABEL "org.label-schema.schema-version" 1.0
Adding LABEL "org.label-schema.usage.singularity.deffile" Singularity
Adding LABEL "org.label-schema.usage.singularity.deffile.bootstrap" docker
Adding LABEL "org.label-schema.usage.singularity.deffile.from" ubuntu:14.04
Adding LABEL "org.label-schema.usage.singularity.version" 2.4-feature-squashbuild-secbuild.g780c84d
Adding command...

4.  Build away, Merrill!
Created container newcontainer:tag
docker inspect newcontainer:tag

```
```
$ docker inspect newcontainer:tag
[
    {
        "Id": "sha256:377b2e59f677aa68281322d55861b8ff22674fce05e76e691030555395c6d5d9",
        "RepoTags": [
            "container:new",
            "newcontainer:tag"
        ],
        "RepoDigests": [],
        "Parent": "sha256:fbe2938963526faecb876ed31486ed024d6251f6aaad926b1993e4f3548903f5",
        "Comment": "",
        "Created": "2018-04-11T03:41:08.255990981Z",
        "Container": "35f0fc90680a49c47868cc74cd54ccd0ecef539c9634ae5f735c9bed31e74763",
        "ContainerConfig": {
            "Hostname": "35f0fc90680a",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                "LD_LIBRARY_PATH=/.singularity.d/libs"
            ],
            "Cmd": [
                "/bin/sh",
                "-c",
                "#(nop) ",
                "CMD [\"/bin/bash\" \"run_singularity2docker.sh\"]"
            ],
            "ArgsEscaped": true,
            "Image": "sha256:fbe2938963526faecb876ed31486ed024d6251f6aaad926b1993e4f3548903f5",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": {
                "MAINTAINER": "vanessasaur",
                "WHATAMI": "dinosaur",
                "org.label-schema.build-date": "2017-10-15T12:52:56+00:00",
                "org.label-schema.build-size": "333MB",
                "org.label-schema.schema-version": "1.0",
                "org.label-schema.usage.singularity.deffile": "Singularity",
                "org.label-schema.usage.singularity.deffile.bootstrap": "docker",
                "org.label-schema.usage.singularity.deffile.from": "ubuntu:14.04",
                "org.label-schema.usage.singularity.version": "2.4-feature-squashbuild-secbuild.g780c84d"
            }
        },
        "DockerVersion": "18.03.0-ce",
        "Author": "",
        "Config": {
            "Hostname": "",
            "Domainname": "",
            "User": "",
            "AttachStdin": false,
            "AttachStdout": false,
            "AttachStderr": false,
            "Tty": false,
            "OpenStdin": false,
            "StdinOnce": false,
            "Env": [
                "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
                "LD_LIBRARY_PATH=/.singularity.d/libs"
            ],
            "Cmd": [
                "/bin/bash",
                "run_singularity2docker.sh"
            ],
            "ArgsEscaped": true,
            "Image": "sha256:fbe2938963526faecb876ed31486ed024d6251f6aaad926b1993e4f3548903f5",
            "Volumes": null,
            "WorkingDir": "",
            "Entrypoint": null,
            "OnBuild": null,
            "Labels": {
                "MAINTAINER": "vanessasaur",
                "WHATAMI": "dinosaur",
                "org.label-schema.build-date": "2017-10-15T12:52:56+00:00",
                "org.label-schema.build-size": "333MB",
                "org.label-schema.schema-version": "1.0",
                "org.label-schema.usage.singularity.deffile": "Singularity",
                "org.label-schema.usage.singularity.deffile.bootstrap": "docker",
                "org.label-schema.usage.singularity.deffile.from": "ubuntu:14.04",
                "org.label-schema.usage.singularity.version": "2.4-feature-squashbuild-secbuild.g780c84d"
            }
        },
        "Architecture": "amd64",
        "Os": "linux",
        "Size": 187796668,
        "VirtualSize": 187796668,
        "GraphDriver": {
            "Data": null,
            "Name": "aufs"
        },
        "RootFS": {
            "Type": "layers",
            "Layers": [
                "sha256:a8d50d7688e2b24b2de0f779f63104f3dbe08e0ddff2658f01f81ffc2d0654be"
            ]
        },
        "Metadata": {
            "LastTagTime": "2018-04-11T00:02:54.777906654-04:00"
        }
    }
]
```
```
$ docker run newcontainer:tag
RaawwWWWWWRRRR!!
$ singularity run singularity-container.sif
RaawwWWWWWRRRR!!
```

Rawr!
