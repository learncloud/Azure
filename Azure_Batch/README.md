Batch는 Azure의 HPC 서비스입니다. 

짧은 시간안에 대규모 컴퓨팅 파워를 이용해 빠르게 계산하는 서비스
ex) 행성간의 거리 계산, 머신러닝, 빅데이터, 딥러닝, 차량충돌테스트, 게놈프로젝트 테스트와 같은 대한 일반적이지 않은 곳에 이용됩니다.


해당 코드는 고객사 Kubernetes에 작업 요청이 들어올시 Azure Batch를 통하여 고사양의 컴퓨터를 1대 생성한후 특정 작업이 종료되면 Batch내의 Node를 죽여 과금을 최소화 하기 위한 로직입니다


1. Terraform으로 Batch account와 Storage Account를 생성합니다
2. REST API를 이용해 Batch 내의 Pool을 생성합니다
3. Pool에 작업이 종료되면 DELETE API를 날려 Batch-Pool(Virtual machine)이 자동 제거 됩니다
