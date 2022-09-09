# docker-cats

A simple web application which serves different content according to a given environment variable.

Used for testing micro-services architectures.

Image is available at Dockerhub - [unfor19/docker-cats](https://hub.docker.com/r/unfor19/docker-cats)

## Run

Available APP_NAME:

- baby
- green
- dark

```bash
docker run --name cats --rm -p 8080:8080 -d  -e APP_NAME=baby unfor19/docker-cats
```

Change the author

```bash
docker run --name cats --rm -p 8080:8080 -d  -e APP_NAME=dark -e FROM_AUTHOR=darker unfor19/docker-cats
```

View the app in local browser via [http://localhost:8080](http://localhost:8080)

## Build From Source

```bash
docker build -t unfor19/docker-cats .
```

<details>

<summary>Deploy in AWS behind Cloudflare - Expand/collapse</summary>

## Deploy in AWS behind Cloudflare

Before we even start, this is how the website should look like after a successful deployment - [https://docker-cats-stg.meirg.co.il](https://docker-cats-stg.meirg.co.il).

### Describing my journey

1. **Provision a least expensive architecture for mockups/proof of concepts**; though still robust architecture. For example, I dodged the bullet of provisioning a Load Balancer (ALB/NLB).
2. Publish an example of how to use GitHub Actions for building a Docker image, pushing it to a Docker registry (AWS ECR in my case) and performing a blue/green deployment to AWS ECS with [ecs-deploy](https://github.com/silinternational/ecs-deploy). I truly believe that this project can be converted from ECS to EKS or any other microservices orchestrator.
3. I've created everything manually for "staging" via AWS Console. During the process, I've collected anything that I can (see [./resources](./resources/)) to ease the future move from "AWS Console to infrastructure as code (IaC)".
4. CICD
   1. Network reachability - First, I added my IP address ([ifconfig.me/ip](https://ifconfig.me/ip)) to the app's security group inbound rules. After checking that the app is reachable from my machine, I moved on to Cloudflare configuration (whitelist Cloudflare CIDR ranges)


### Infrastructure

#### Create AWS Resources

Create the following AWS resources in the AWS console

1. [VPC (New VPC Experience)](https://eu-west-1.console.aws.amazon.com/vpc/home?region=eu-west-1#) > Launch VPC Wizard > **VPC, subnets, etc.**
   1. Tick **Auto-generate** > Value: `docker-cats-stg`
   2. Set **VPC endpoints** to **None**
2. [ECS Cluster (Old ECS Experience)](https://eu-west-1.console.aws.amazon.com/ecs/home?region=eu-west-1#/clusters)
     1. Click **Create cluster**
     2. Select **Networking only**
     3. Cluster Name: `docker-cats-stg`
     4. Click **Create**
3. [ECS Task Definition](https://eu-west-1.console.aws.amazon.com/ecs/home?region=eu-west-1#/taskDefinitions)
     1. Before we start - make sure the IAM role `ecsTaskExecutionRole` exists; The role is required by the AWS ECS Service to manage ECS Tasks, that includes pulling private images from ECR if necessary
     2. Click **Create new Task Definition**
     3. Select **FARGATE** (Read more about [AWS Fargate](https://aws.amazon.com/fargate/))
     4. Scroll down and click **Configure via JSON**
     5. Copy the contents of [resources/app_ecs_task_definition.json](./resources/app_ecs_task_definition.json) and paste it in the **JSON** text area
     6.  Find and replace `123456789012` with the relevant AWS account number
     7.  Click **Create**
4. [ECS Service (Old ECS Experience)](https://eu-west-1.console.aws.amazon.com/ecs/home?region=eu-west-1#/clusters/docker-cats-stg/services)
     1. Click **Create**
     2. Launch Type: `FARGATE`
     3. Task Definition: `docker-cats-stg`, Revision: *select latest* (previosuly created)
     4. Select the previously created VPC `docker-cats-stg-vpc`
     5. Service Name: `docker-cats-stg`
     6. Number of tasks: `1`
     7. Click **Next step** (Configure service)
     8. Cluster VPC: `docker-cats-stg` (previosuly created)
     9. Subnets: select two public subnets`docker-cats-stg-subnet-public`
     10. Review > Click **Next step** (Configure network)
     11. Click **Next step** (Set Auto scaling)
     12. Click **Create Service** (Review)

#### Allow inbound from Cloudflare only

Allow inbound from Cloudflare only, according to the following list - https://www.cloudflare.com/ips-v4

1. AWS Console > VPC > Security Groups > Search `docker-cats` and get the Security group ID
2. Run the following script to add Cloudflare's IP Ranges to the security group's inbound rules
     ```bash
     # Requires AWS CLI and curl
     export \
         SECURITY_GROUP_ID="sg-0d7209c7061234567"
         AWS_REGION="eu-west-1"
     ./scripts/set_inbound_cidr.sh
     ```

By default, Cloudflare proxies to known [HTTPS ports](https://developers.cloudflare.com/fundamentals/get-started/reference/network-ports/). 

I've set the app to listen on port `80` and allowed inbound access to port `80` only from [Cloudflare's servers CIDR Ranges](https://www.cloudflare.com/ips/)


#### Recap

Currently, there's an ECS Task which runs `docker-cats` and has a public IP. To access the application, add your IP address to the Security Group inbound rules on port `80` to check if it's running properly

```bash
APP_PUBLIC_IP="123.123.123.123"
curl -L "$APP_PUBLIC_IP"
```

If you see `<html lang="en">...` in the response, you're good to go.

Next up, mapping Cloudflare DNS record to the task's public IP with an A record. The downside, is that each time the ECS task restarts/stops, the public IP changes, we'll get to that.

#### Map Cloudflare to ECS Task public IP

1. [Login to Cloudflare](https://dash.cloudflare.com/)
2. Click on relevant domain
3. Click **DNS** > Click **Add record**
   1. Name: `docker-cats-stg`
   2. Value: `public IP of ECS Task` (keep the **Proxied ON**)
4. Click **Rules** > **Click Create Page Rule**
   1. **URL**: `docker-cats*.SELECTED_DOMAIN_NAME/*` (my `SELECTED_DOMAIN_NAME` is `meirg.co.il`)
   2. Click **Add setting** > **SSL** > **Flexible** ([Cloudflare's SSL policies](https://www.cloudflare.com/ssl/))

Finally, `docker-cats-stg.meirg.co.il` is mapped in Cloudflare to proxy traffic to the public IP of the ECS task.

Final result - [https://docker-cats-stg.meirg.co.il](https://docker-cats-stg.meirg.co.il)

```
Cloudflare --> meets AWS security group rules --> ECS Task public IP
```

</details>

## References

- [app/images/baby.jpg](./app/images/baby.jpg) source https://www.findcatnames.com/great-black-cat-names/ - [img](https://t9b8t3v6.rocketcdn.me/wp-content/uploads/2014/10/black-cat-and-moon.jpg)
- [app/images/green.jpg](./app/images/green.jpg) source http://challengethestorm.org/cat-taught-love/ - [img](http://challengethestorm.org/wp-content/uploads/2017/03/cat-2083492_700x426.jpg)
- [app/images/dark.jpg](./app/images/dark.jpg) source https://www.maxpixel.net/Animals-Stone-Kitten-Cats-Cat-Flower-Pet-Flowers-2536662


## Authors

Created and maintained by [Meir Gabay](https://github.com/unfor19)

## License

This project is licensed under the MIT License - see the [LICENSE](https://github.com/unfor19/docker-cats/blob/master/LICENSE) file for details
