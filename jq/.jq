def ec2_list: .Reservations[].Instances[] | { Name: .Tags[] | select(.Key=="Name").Value, Status: .State.Name, Type: .InstanceType, Launched: .LaunchTime };
