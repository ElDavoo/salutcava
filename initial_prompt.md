# Salut, ca va?

In France, people greet each other with two conversation turns that look like a TCP handshake:

1. Person A: "Salut"
2. Person B: "Salut, ca va?"
3. Person A: "Ca va, et toi?"
4. Person B: "Ouais, ca va."

Only after this exchange can the conversation proceed to other topics. 
Additionally, in a multi-person conversation, each person must greet every other person before the conversation can proceed.  

## 2-step protocol variant

To not lock a pair of people for too much, since they might be busy discussing with someone or anything, a variation of the protocol is often used, which is less efficient but divided into two different batches, that can be interrupted.  

### Step 1

1. Person A: "Salut"
2. Person B: "Salut"

### Step 2

1. Person A: "Ca va?"
2. Person B: "Ca va, et toi?"
3. Person A: "Ouais, ca va."

## What needs to be done

A Flutter application that simulates a group of people in circle meeting each other and following this protocol.  
The user should be able to choose:

- The number of people in the circle (between 2 and 20)
- How many people can talk at the same time (between 1 and 5)

The application should then show the people (as icons) in a circle, and show the conversation as 
bubbles and arrows between the people. (e.g. Person A says "Salut" to Person B, then an arrow from A to B with a bubble showing "Salut").  

The user has to press on the screen to advance the conversation at each step.  
When everyone has greeted everyone, the user should see the total number of conversation turns taken, and the total time taken.  

## Development context  

The application should be developed in Flutter, and should be runnable on Android.  
I'm using NixOS, so the development environment should be set up using Nix.