# Zephyr Ceedling Module

Copyright (c) 2023 Efrian Calderon

This Zephyr module rintegrates Ceedling framework. This work is
inspired by these two projects:

* Nhttps://github.com/nrfconnect/sdk-nrf/
* https://github.com/antmicro/zephyr-cmock-unity-module

For a more in-depth test creation description using this
module refer to [this document](CREATING_TESTS.md).

## Installation

This instruction was tested on Ubuntu 22.04. Install
dependencies:

```
sudo apt update
xargs sudo apt install -y < dependencies.lst
```

Setup Zephyr SDK:

https://docs.zephyrproject.org/latest/develop/toolchains/zephyr_sdk.html

Clone this repository:
```
git clone https://github.com/efra-mx/zephyr-ceedling.git
cd zephyr-ceedling
```

Setup Python dependencies:

```
pip3 install -r requirements.txt
```

An example project manifest that uses this module is provided in
`project-example.yml`. To use it, type:

```
west init --local --mf project-example.yml
```

Next, set Zephyr RTOS and its dependencies up:

```
west update
west zephyr-export
pip3 install -r ../zephyr/scripts/requirements.txt
```

## Samples

You can build and run samples with:

```
west build -p -b native_posix tests/unity -t run
west build -p -b native_posix tests/cmock -t run
```

You can also run samples in Renode with:
```
west build -p -b <platform_name> tests/unity -t run_renode
west build -p -b <platform_name> tests/cmock -t run_renode
```
Where `<platform_name>` is the Zephyr platform of your choice.

## Configuration options

You can use custom configs by setting below CMake variables
| Variable name | Description |
|---------------|------------|
| CMOCK_CONFIG | Path to custom `cmock_cfg.yaml` config file |
| UNITY_CONFIG | Path to custom `unity_cfg.yaml` config file |

## Twister

Tests located under the `tests` directory support Zephyr's `twister` script. To
use it, run the following command from this module's main directory:
```
../zephyr/scripts/twister --testsuite-root tests
```

You can also select a specific platform you want to run these tests on with
Twister. To do that, use the `-p <platform_name>` switch:
```
../zephyr/scripts/twister -p <platform_name> --testsuite-root tests
```
