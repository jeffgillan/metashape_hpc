# Agisoft Metashape on HPC

[Agisoft Metashape](https://www.agisoft.com/) is a proprietary structure-from-motion photogrammetry software program. It is an industry leader in creating orthomosaics, digital elevation models, and 3D point clouds from overlapping imagery (aerial, drone, or ground-based). 

## Licensing
The University of Arizona [Data Science Institute](https://datascience.arizona.edu/)(DSI) and the [Institute for Computation and Data-Enabled Insight](https://datainsight.arizona.edu/)(ICDI) have purchased 20 floating licenses for Metashape versions 2.x.x. The licenses are intended to be used for cloud computing or High Performance Computing (HPC) for University of Arizona personnel.

* The licenses do not expire
* Licenses can be used for Linux, Windows, or Mac OS
* Use of the license is managed through a license server. The license server is a m3.tiny virtual machine on Jetstream2 using the Open Forest Observatory allocation (BIO220124). The license server was set up by Jeremy Frady.
* [Floating license activation procedure](https://agisoft.freshdesk.com/support/solutions/articles/31000169229--metashape-2-x-floating-license-activation-procedure)
* [How to run a license server as a system service](https://agisoft.freshdesk.com/support/solutions/articles/31000169438--metashape-2-x-how-to-run-license-server-as-a-system-service)
* To use the license, users need to have or create a file called `server.lic`. This file specifies the IP address and port of the license server.
* The `server.lic` file should be placed within the local directory where Metashape is installed. For linux machines, the location would be `/opt/metashape-pro`. For Windows machines, the location could be `C:/program files/agisoft/metashape pro/` or similar. For macOS users, the location could be `/Library/Application Support/Agisoft/Licensing/licenses`
* The license information is not publicized to prevent unauthorized people from using it. Please contact Jeff Gillan (jgillan@arizona.edu) or Tyson Swetnam (tswetnam@arizona.edu) if you are interested in using the license. 
 

## Containerize with Docker

The Dockerfile to build the Metashape container image is located in this repository. It builds Agisoft Metashape v2.1.1 using Ubuntu Focal Fossa (20.04). It includes the GUI and Python 3 Module. The license file is NOT included in this repository. To build the docker image, first clone the repo to your local machine. 

```
docker build -t jeffgillan/agisoft-metashape:cudagl-20.04 .
```

### Push Built Docker image to Cyverse Container Registry

Push the built docker image and park it in Cyverse container registry https://harbor.cyverse.org. The image is set to private, meaning it can not be pulled without specific authorization (i.e., a Cyverse login that has been given permission by Sarah Roberts).

```
docker tag jeffgillan/agisoft-metashape:cudagl-20.04 harbor.cyverse.org/vice-private/agisoft-metashape:cudagl-20.04
```
```
docker push harbor.cyverse.org/vice-private/agisoft-metashape:cudagl-20.04
```

### Run Containerized Metashape GUI on your local machine

When you run the container, you must be on the UA campus, or be on the [University of Arizona VPN](https://vpn.arizona.edu), so that the software can access the floating license manager. If you are not on these, the software will launch in the trial version.

Launch containerized Agisoft Metashape WITHOUT GPUs
```
xhost +local:root
docker run -ti --rm -e DISPLAY=unix$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix:rw -v /home/$USER/:/user_home harbor.cyverse.org/vice-private/agisoft-metashape:cudagl-20.04
```

Launch containerized Agisoft Metashape WITH GPUs
```
xhost +local:root
docker run --gpus all -ti --rm -e DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix -v /home/$USER/:/user_home harbor.cyverse.org/vice-private/agisoft-metashape:cudagl-20.04
```


<br/>
<br/>

## Metashape on HPC
Agisoft Metashape can run on a single local computer, but it is also designed to run across multiple processing nodes in order to speed up processing of large imagery datasets. See the [HPC Documentation](https://hpcdocs.hpc.arizona.edu/).

### Transfer Data onto HPC directories

`rsync -azPr <my_directory_of_data> jgillan@filexfer.hpc.arizona.edu:/home/u5/jgillan`


### HPC Open OnDemand

https://ood.hpc.arizona.edu/

From the Open OnDemand, start an interactive Desktop 

Launch a terminal on the graphical desktop

Type the following commands to set up authentication to be able to pull docker image from private cyverse container registry

```
export SINGULARITY_DOCKER_USERNAME='cyverse username here'
export SINGULARITY_DOCKER_PASSWORD='cyverse harbor CLI secret'
```
The CLI secret is found in the user profile once you login to https://harbor.cyverse.org

<img src="https://github.com/jeffgillan/agisoft_metashape/blob/main/images/harbor.png" width=450>

<br/>
<br/>
Next, you will pull the private docker image onto the HPC. Type:

`singularity pull docker://harbor.cyverse.org/vice-private/agisoft-metashape:cudagl-20.04`

<br/>
<br/>

## Launch Metashape GUI

Type the following to run the container. This should launch the Agisoft GUI. 

`singularity exec agisoft-metashape_cudagl-20.04.sif /opt/metashape-pro/metashape.sh`

<br/>
<br/>

Alternatively, you can launch the container with the following commands:

```
singularity shell agisoft-metashape_cudagl-20.04.sif  ## get into the container shell

Apptainer> cd /opt/metashape-pro

Apptainer> ./metashape.sh
```

If the license server is working, the Agisoft GUI should launch quickly. If they is a large delay, the license server may be down. After serveral minutes, the search for the license server will time out, and the GUI will launch anyway but without license. 


<br/>
<br/>

Open an additional terminal. The first terminal will remain running the container. 

<br/>

In the new terminal, get the IP address of the host computer. 
 
 `hostname -i`

 It will return something like *10.141.33.112*

<br/>
<br/>

In the Agisoft GUI menu, go to Tools >>> Preferences >>> Network

Check mark the *Enable network processing* switch

Fill in the *Host Name* with IP address we looked up in the previous step. (i.e., *10.141.33.112*)

Port Number should be *5840*

*Root* is the directory where the image data is kept.  For data in personal directory use `/home/u5/jgillan/100_0123`

Within the same *Metashape Preferences* menu, go to the *GPU* tab and make sure the button for *Use CPU when performing GPU accelerated processing* in UNCHECKED.

Within the same *Metashape Preferences* menu, go to *Advanced* tab and make sure the button *Enable fine-level task subdivision* is CHECKED.

Click OK to close the *Preferences* dialogue box. 

<br/>
<br/>

### Start a Server Node in Server Mode

Back at the terminal, type:


```
apptainer exec agisoft-metashape_cudagl-20.04.sif /opt/metashape-pro/metashape.sh --server --host 10.141.33.112 --root /home/u5/jgillan/100_0123 
```

Alternatively, you could type:

```
singularity shell agisoft-metashape_cudagl-20.04.sif

Apptainer> cd /opt/metashape-pro

Apptainer> ./metashape.sh --server --host 10.141.33.112 --root /home/u5/jgillan/100_0123
```


<img src="https://github.com/jeffgillan/agisoft_metashape/blob/main/images/server_instance.png" width=600>


<br/>
<br/>

## Launch Network Monitor

Open an additional terminal within your interactive desktop 

`apptainer exec agisoft-metashape_cudagl-20.04.sif /opt/metashape-pro/monitor.sh`

or

```
singularity shell agisoft-metashape_cudagl-20.04.sif

Apptainer> cd /opt/metashape-pro

Apptainer> ./monitor.sh
```

<br/>
<br/>

The monitor GUI should launch quickly.

Type the IP address into the *Host Name*. Then click *Connect* 

<img src="https://github.com/jeffgillan/agisoft_metashape/blob/main/images/monitor.png" width=700>

There should be an indication that the monitor is connected to the server (on the bottom of the monitor window).

<br/>
<br/>


You should now have 3 terminals each doing something different 

Terminal 1: Metashape GUI

Terminal 2: Server Node

Terminal 3: Monitor

<br/>

## Launch Processing Nodes

In Open OnDemand, launch *Clusters* >>> *Shell Access*. This will open a terminal

In the terminal choose your HPC system by typing for example: 
`ocelote`

It is probably a good idea that all components of your network processing system use the same HPC

<br/>

Request an interactive CPU processing node

`interactive -n 16 -m 6GB -a jgillan -t 24:00:00`

To get a GPU node

`interactive -g -n 8 -m 9GB -a jgillan -t 24:00:00`

This may take some time to get the node or it might be instantly.

Once you have the node, type the following commands to launch workers. 


Launch GPU worker node:

```
apptainer exec --nv agisoft-metashape_cudagl-20.04.sif /opt/metashape-pro/metashape.sh --worker --host 10.141.32.65 --root /groups/jgillan/gillan_lizard/images --capability gpu -platform offscreen
```
<br/>

Launch CPU worker node:

```
apptainer exec agisoft-metashape_cudagl-20.04.sif /opt/metashape-pro/metashape.sh --worker --host 10.141.32.159 --root /groups/jgillan/gillan_lizard/images --capability cpu -platform offscreen
```

<br/>
<br/>

If you successfully launched a processing node then you should see the following output

<img src="https://github.com/jeffgillan/agisoft_metashape/blob/main/images/process_node.png" width=700>

<br/>
<br/>

Back on the interactive desktop, you should see that the node was added in the network monitor


<img src="https://github.com/jeffgillan/agisoft_metashape/blob/main/images/monitor_nodes.png" width=700>

Repeat the process of *Launching Processing Nodes* to add more processing power for your Metashape project. You need several cpu only and several gpu only nodes because different processing steps of Metashape require different resources.



<br/>
<br/>

## Regular Metashape Workflow

Now that you have your processing engine set-up, you can go back to the Metashape GUI and go through the normal workflow. Before any processing can occur, be sure that you have saved the project as .psx file. 


It is recommended to use the _Batch_ processing method. This way, the project is saved after completing each task. 

Image Matching - GPU Distributed
Align Photos - CPU distributed but final merging (60-100%) is on one node
Optimize Alignment - CPU - cannot be distributed



<br/>





## Transfer data from one user to another on HPC
One option is to invite a user to join your group. The user can get files that are in the group director `/groups/jgillan`. After the user gets the file, then you can remove them from your group, if you want. 

You can add and remove people to the group by going here https://portal.hpc.arizona.edu/

<br/>
<br/>
<br/>



## Logging into UA HPC from local command line


If you have a UA account, to connect to the HPC you need to use `ssh` ([Secure Shell](https://en.wikipedia.org/wiki/Secure_Shell)). Open a terminal, and type:

```
ssh <UA username>@hpc.arizona.edu
```

Type your UA password and if successful you'll be greeted with a two-factor login. Select which choice, and complete the authentification. Once you are past the authentification steps, you will enter the [Bastion server](https://en.wikipedia.org/wiki/Bastion_host). This step has 2 purposes: 

1. Protect from attacks.
2. Select what HPC system you want to use.

!!! warning "Note: the Bastion server is NOT YET the HPC! Here you cannot submit jobs or run analyes. Type `shell` in order to select what system you want to use."

The whole process (from logging to selecting the system) looks like the following:

```
ssh cosi@hpc.arizona.edu
(cosi@hpc.arizona.edu) Password: 
(cosi@hpc.arizona.edu) Duo two-factor login for cosi

Enter a passcode or select one of the following options:

 1. Duo Push to XXX-XXX-8418
 2. SMS passcodes to XXX-XXX-8418

Passcode or option (1-2): 1
Success. Logging you in...
Last login: Tue Mar 26 14:52:39 2024 from dhcp-10-132-212-1.uawifi.arizona.edu
This is a bastion host used to access the rest of the RT/HPC environment.

Type "shell" to access the job submission hosts for all environments
-----------------------------------------

[cosi@gatekeeper ~]$ shell
Last login: Wed Mar 20 10:30:25 2024 from gatekeeper.hpc.arizona.edu
***
The default cluster for job submission is Puma
***
Shortcut commands change the target cluster
-----------------------------------------
Puma:
$ puma
(puma) $
Ocelote:
$ ocelote
(ocelote) $
ElGato:
$ elgato
(elgato) $
-----------------------------------------

[cosi@wentletrap ~]$ ocelote
(ocelote) [cosi@wentletrap ~]$
```

At this point you are in the Login Node, where you can submit jobs or ask for an interactive node.

<img src="https://uarizona.atlassian.net/wiki/download/thumbnails/75989999/HPCDiagram_FileTransfers.png?version=1&modificationDate=1696282205000&cacheVersion=1&api=v2&effects=drop-shadow&width=1124&height=686" width=750>


