# Exploiting an ERC777-token Uniswap Exchange

[![standard-readme compliant](https://img.shields.io/badge/readme%20style-standard-brightgreen.svg?style=flat-square)](https://github.com/RichardLitt/standard-readme)

> Exploiting any Uniswap exchange that trades an ERC777 token by leveraging the reentrant microtrading attack vector

## Table of Contents

- [Install](#install)
- [Run](#run)
- [Exploit details](#exploit-details)
  - [Why it works](#why-it-works)
- [Learning resources](#learning-resources)
- [Disclaimer](#disclaimer)

## Install

1. Setup a Python virtual environment
~~~
$ pip3 install virtualenv
$ virtualenv -p python3 venv
~~~

2. Activate virtual env & install Python dependencies (just Vyper)
~~~
$ source venv/bin/activate
$ pip install -r requirements.txt
~~~

If `source venv/bin/activate` does not work for you, try out with `bash venv/bin/activate`.

3. Install NPM dependencies
~~~
$ npm install
~~~

## Run

Once in the virtual environment (where Vyper must be installed), run
~~~
(venv)$ npm test
~~~

## Exploit details

The proof of concept for the exploit is located in the `test/uniswap.exploit.js` file. It takes care of setting up the entire environment and running three test case scenarios.

[The environment consists of](test/uniswap.exploit.js#L85):

- A "template" Exchange
- A Uniswap Exchange Factory (see [`uniswap_factory.vy`](contracts/uniswap_factory.vy) - taken from [Uniswap's repository](https://github.com/Uniswap/contracts-vyper/blob/c10c08d81d6114f694baa8bd32f555a40f6264da/contracts/uniswap_factory.vy))
- The ERC777 token to be exchanged
- The ERC1820 registry to register interfaces
- The actual Exchange for the token (see [`uniswap_exchange.vy`](contracts/uniswap_exchange.vy) - taken from [Uniswap's repository](https://github.com/Uniswap/contracts-vyper/blob/c10c08d81d6114f694baa8bd32f555a40f6264da/contracts/uniswap_exchange.vy))
- Sending / approving the necessary ETH and tokens to all actors

The three test cases are:

1. [Legitimate trading with a single external sale:](test/uniswap.exploit.js#L133) a user that holds tokens wants to operate on the exchange, to deposit tokens and receive ETH. This is done in a single transaction calling the `tokenToEthSwapInput` function. This is the regular use case for a Uniswap exchange.

2. [Legitimate trading with multiple external sales:](test/uniswap.exploit.js#L174) same as case (1), but now the user submits multiple transactions instead of just 1. Therefore, this results in less profit than (1).

3. [Exploiting:](test/uniswap.exploit.js#L191) the attacker deploys an attacker contract that will be in charge of operating in the exchange. The exploit is executed in a single transaction, reentering several times in the vulnerable function `tokenToEthSwapInput` by leveraging the ERC777 `tokensToSend` hook.

### Why it works

By leveraging the `tokensToSend` hook, the attacker contract is called _after_ receiving ETH (_i.e._ the exchange ETH balance has decreased) but _before_ the token balance is modified (_i.e. the exchange token balance has not decreased_). As a consequence, reentering the vulnerable `tokenToEthSwapInput` will re-calculate the token-ETH exchage price, but this time with less ETH and same amount of tokens in reserves. Thus, the exchange will be buying the attacker tokens, paying in ETH, at a higher price than it should.

## Learning resources
- [Uniswap docs](https://docs.uniswap.io/)
- [EIP 777 - tokensToSend hook](https://eips.ethereum.org/EIPS/eip-777#erc777tokenssender-and-the-tokenstosend-hook)
- Reentrancy attack: [SWC 107](https://smartcontractsecurity.github.io/SWC-registry/docs/SWC-107)

## Disclaimer
This is a proof-of-concept exploit of an already [public, disclosed](https://github.com/ConsenSys/Uniswap-audit-report-2018-12#31-liquidity-pool-can-be-stolen-in-some-tokens-eg-erc-777-29) and [acknowledged](https://twitter.com/UniswapExchange/status/1120423109440438275) vulnerability in Uniswap related to reentrancy attacks. Were that not the case, under no circumstances this proof-of-concept exploit would have been made public. Should you find any 0-day vulnerability in these contracts, please report directly to [Uniswap](https://github.com/Uniswap/contracts-vyper).
