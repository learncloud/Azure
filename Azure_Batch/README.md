Batch는 Azure의 HPC 서비스입니다. 

짧은 시간안에 대규모 컴퓨팅 파워를 이용해 빠르게 계산하는 서비스
ex) 행성간의 거리 계산, 머신러닝, 빅데이터, 딥러닝, 차량충돌테스트, 게놈프로젝트 테스트와 같은 대한 일반적이지 않은 곳에 이용됩니다.


해당 코드는 고객사 Kubernetes에 작업 요청이 들어올시 Azure Batch를 통하여 고사양의 컴퓨터를 1대 생성한후 특정 작업이 종료되면 Batch내의 Node를 죽여 과금을 최소화 하기 위한 로직입니다


1. Terraform으로 Batch account와 Storage Account를 생성합니다
2. REST API를 이용해 Batch 내의 Pool을 생성합니다
3. Pool에 작업이 종료되면 DELETE API를 날려 Batch-Pool(Virtual machine)이 자동 제거 됩니다


>create_batch_account_custompool_autoscal.json 코드 리뷰

리뷰할 Code는 해당 Json의 autoScale부분에 대한 것입니다.

노드가 생성되자마자 0이 됩니다. 그 이유는실행할 작업이 없기 때문에 생성되자마자 노드가 0이되는 것

```
1)	실행할 준비가 되었지만 아직 실행되지 않은 작업 수($ActiveTasks) 중에서 지난 5분 (TimeInterval_Minute * 5) 동안의 사용할 수 있는 샘플의 백분율(GetSamplePercent())를 반환합니다. 

Batch에서 샘플은 30초마다 기록되며 샘플을 기록한 시간과 autoscale formula에서 사용할 수 있는 시간 사이에 지연이 있을 수 있습니다. 즉 첫 번째 명령은 지난 5분간 실제 발생한 샘플과 수집된 샘플의 %를 계산하는 식입니다. 

2)	수집한 샘플이 70%는 넘는 경우(true인 경우) 즉 신뢰할 만한 수준이라고 판단되는 경우 max(0, $ActiveTasks.GetSample(1)) 식이 평가됩니다. GetSample(1)은 Batch 서비스에 경과한 시간에 관계없이 마지막 샘플의 값을 요구 사합니다. 결과적으로 샘플의 값과 0 중에서 큰 값을 선택합니다.
$sample 값이 70% 이하인 경우(false인 경우) GetSample(1) 값과 지난 4분간 수집한 샘플의 평균 값 중 큰 값을 선택합니다. 


```
<pre><code>
$samples = $ActiveTasks.GetSamplePercent(TimeInterval_Minute * 5);
$tasks = $samples < 70 ? max(0, $ActiveTasks.GetSample(1)) : max( $ActiveTasks.GetSample(1), avg($ActiveTasks.GetSample(TimeInterval_Minute * 4)
</code></pre>
