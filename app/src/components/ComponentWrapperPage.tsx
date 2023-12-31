import { VmComponent } from "@/components/vm/VmComponent";
import { componentsByNetworkId } from "@/data/bos-components";
import { MetaTags } from "./MetaTags";
import styled, { keyframes } from "styled-components";
import { useEffect, useState } from "react";

type Props = {
  componentProps?: Record<string, unknown>;
  src: string;
  meta?: {
    title: string;
    description: string;
  };
};

const SpinnerAnimation = keyframes`
  0% {
    transform: rotate(0deg);
  }
  100% {
    transform: rotate(360deg);
  }
`;

const SpinnerWrapper = styled.div`
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  height: 100vh;
`;

const LoadingText = styled.p`
  margin-top: 20px;
  font-size: 20px;
`;

const Spinner = styled.div`
  border: 6px solid #f3f3f3;
  border-top: 6px solid #0e6efd;
  border-radius: 50%;
  width: 50px;
  height: 50px;
  animation: ${SpinnerAnimation} 2s linear infinite;
`;

const Component = ({ src }: { src: string }) => (
  <VmComponent
    src={componentsByNetworkId["mainnet"]![src].id}
    props={componentsByNetworkId["mainnet"]![src].props}
  />
);

export function ComponentWrapperPage(props: Props) {
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const fn = () => {
      setReady(true);
    };
    window.addEventListener("load", fn);
  }, []);

  if (!ready) {
    return (
      <SpinnerWrapper>
        <Spinner />
        <LoadingText>Fetching Components from the BlockChain...</LoadingText>
      </SpinnerWrapper>
    );
  }

  return (
    <>
      {props.meta && <MetaTags {...props.meta} />}

      <Component src={"landing"} />
      {/* <Component src={"input"} /> */}
    </>
  );
}
