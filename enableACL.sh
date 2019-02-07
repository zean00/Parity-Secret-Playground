#!/bin/bash
sed -i '' -e  's,acl_contract = "none",acl_contract = "5419c76b4de5ff64efb45e464af6fed52247581d",g' parity/config/secret/ss1.toml parity/config/secret/ss2.toml parity/config/secret/ss3.toml
