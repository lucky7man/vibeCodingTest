git status 와 diff 를 통해 변경사항 확인
github issues를 확인
변경된 파일이 많을 경우 분리해서 순차적으로 커밋을 진행한다.
github issues에 해당 커밋에 대한 내용을 기록한다. 특히 주석에 AC에 적혀있는 해당 작업이 끝났음을 증명할 수 있는 증거자료를 남긴다.
git add 를 통해 변경사항 추가
git commit -m "" 를 통해 커밋. 이슈 번호를 포함한다.
절대 git hook에서 수행하는 검증을 건너뛰지 않는다. '--no-verify'옵션 사용 금지!!
git push 를 통해 변경사항을 원격 저장소에 푸시한다.