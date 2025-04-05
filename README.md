# Janction Layer 1 Node

**Janction's Layer 1 the first trully decentralized video rendering blockchain.**

### Video Rendering use case

The first use case to be supported is currently video rendering.

Starts with a animator uploading the Blender animation and creating a task specifying frames to be rendered, amount of computers to be paralelized on and the reward.


<p align="center">
  <img src="https://janction-layer1.s3.us-east-2.amazonaws.com/Layer+1.drawio.png" alt="Video Rendering"/>
</p>

Task is divided into Threads which allow up to 10 nodes to subscribe and gain a spot in the competition.

After blockchain confirms their spot, they will start rendering frames from that thread in a competition where the fastest will win.

Once a winner is declared, competing nodes will start verification by submitting a ZKP of their local rendered files and compare with the solution proposed by the winner.

**The blockchain itself makes sure the work is valid and done as expected**

### Janction's consensus algorithm -  Proof of Completion 

[To be documented soon]


## Development Status

Layer 1 node is currently under development. We are very close on being able to start our public testnet with more instructions to configure and join to be available soon.


## Compilation

1) Clone repositories

```
git clone https://github.com/acostarodrigo/janctionLayer1Node layer1Node
```

Also clone the video rendering module on a folder called videoRendering

```
git clone https://github.com/acostarodrigo/janctionVideoRenderingModule videoRendering
```

2) compile
   ```
   $ cd layer1Node
   $ git checkout janction
   $ make install
   ```

3) Test and run the node
   
   ```
    $ make init
    $ janctiond start
   ```

## Testnet

Instructions to join the testnet and contribute with your own node will be available soon.